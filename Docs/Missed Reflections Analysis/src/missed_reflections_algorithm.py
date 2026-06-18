from datetime import timedelta
from .models import Interval, MissedReflection
import json
from pathlib import Path
import pandas as pd

def check_missed_reflections(reminders):
    """
    Detect missed reflections based on step and heart rate data with a delay mechanism, followed by post-processing.

    This function evaluates an array of Reminder objects against step and heart rate data loaded
    from 'stepData.json' and 'heartRateData.json' to identify instances where thresholds are
    exceeded within specified intervals. It includes a delay mechanism to prevent multiple
    triggers within a short timeframe for the same reminder. Post-processing filters reflections
    by measurement type, keeps all strong reflections, and removes redundant non-strong reflections.

    - For Steps: Uses a sliding window for intervals (30 Minutes, 1 Hour, 2 Hours, 4 Hours) to sum steps,
      and totals all steps for '1 Day'.
    - For Heart Rate: Checks individual samples for 'Immediately', and uses a sliding window for
      '5 Minutes', '10 Minutes', '15 Minutes', '30 Minutes', '1 Hour' to ensure heart rate exceeds
      the threshold.

    Args:
        reminders (list): List of Reminder objects (measurement_type: "Steps" or "Heart Rate").

    Returns:
        list: List of MissedReflection objects for triggered conditions after filtering.

    Raises:
        FileNotFoundError: If 'stepData.json' or 'heartRateData.json' are not found.
    """
    # Load data from JSON files
    step_file = Path('stepData.json')
    heart_rate_file = Path('heartRateData.json')
    
    if not step_file.exists():
        raise FileNotFoundError("stepData.json not found in the current directory")
    if not heart_rate_file.exists():
        raise FileNotFoundError("heartRateData.json not found in the current directory")
    
    with open(step_file, 'r') as f:
        step_data = json.load(f)
    with open(heart_rate_file, 'r') as f:
        heart_rate_data = json.load(f)
    
    # Convert date strings to datetime objects
    for sample in step_data:
        sample['startDate'] = pd.to_datetime(sample['startDate']).to_pydatetime()
        sample['endDate'] = pd.to_datetime(sample['endDate']).to_pydatetime()
    for sample in heart_rate_data:
        sample['startDate'] = pd.to_datetime(sample['startDate']).to_pydatetime()
        sample['endDate'] = pd.to_datetime(sample['endDate']).to_pydatetime()

    triggered_reflections = []
    last_trigger_times = {reminder.id: None for reminder in reminders}
    
    # Create debug directory
    debug_dir = Path('debug')
    debug_dir.mkdir(exist_ok=True)
    
    # Step 1: Generate raw candidate reflections
    for reminder in reminders:
        if reminder.measurement_type == "Steps":
            if reminder.interval == Interval.ONE_DAY:
                total_steps = sum(sample['stepCount'] for sample in step_data)
                if total_steps > reminder.threshold:
                    window_end = max(sample['endDate'] for sample in step_data)
                    triggered_reflections.append(MissedReflection(reminder, window_end))
            else:
                for i in range(len(step_data)):
                    current_sample = step_data[i]
                    window_end = current_sample['endDate']
                    window_start = window_end - timedelta(seconds=Interval.time_interval(reminder.interval))
                    total_steps = 0
                    
                    for j in range(i, -1, -1):
                        sample = step_data[j]
                        sample_start = sample['startDate']
                        sample_end = sample['endDate']
                        if sample_end <= window_end and sample_start >= window_start:
                            total_steps += sample['stepCount']
                        if sample_start < window_start:
                            break
                    
                    if total_steps > reminder.threshold:
                        last_trigger = last_trigger_times[reminder.id]
                        delay = Interval.buffer(reminder.interval)
                        if last_trigger is None or (window_end - last_trigger) >= delay:
                            triggered_reflections.append(MissedReflection(reminder, window_end))
                            last_trigger_times[reminder.id] = window_end
        
        elif reminder.measurement_type == "Heart Rate":
            # Create a debug file for this reminder based on its interval
            debug_filename = debug_dir / f"heart_rate_{reminder.interval.lower().replace(' ', '_')}.txt"
            with open(debug_filename, 'w') as debug_file:
                debug_file.write(f"Heart Rate Missed Reflections Debug Log - Interval: {reminder.interval}\n")
                debug_file.write("=====================================\n\n")
                debug_file.write(f"Reminder Details:\n")
                debug_file.write(f"  Interval: {reminder.interval}\n")
                debug_file.write(f"  Threshold: {reminder.threshold} bpm\n")
                debug_file.write("--------------------------------------------------\n\n")
                
                if reminder.interval == Interval.IMMEDIATELY:
                    for sample in heart_rate_data:
                        if sample['heartRate'] > reminder.threshold:
                            window_end = sample['startDate']
                            last_trigger = last_trigger_times[reminder.id]
                            delay = Interval.buffer(reminder.interval)
                            
                            # Log details for Immediately interval
                            debug_file.write(f"Sample Evaluation:\n")
                            debug_file.write(f"  Timestamp: {window_end}\n")
                            debug_file.write(f"  Heart Rate: {sample['heartRate']} bpm\n")
                            debug_file.write(f"  Exceeds Threshold: True (Threshold: {reminder.threshold} bpm)\n")
                            
                            # Delay check
                            delay_passed = last_trigger is None or (window_end - last_trigger) >= delay
                            debug_file.write(f"  Delay Check:\n")
                            debug_file.write(f"    Last Trigger: {last_trigger}\n")
                            debug_file.write(f"    Delay: {delay}\n")
                            debug_file.write(f"    Delay Passed: {delay_passed}\n")
                            
                            if delay_passed:
                                debug_file.write("  Outcome: Reflection Triggered\n")
                                triggered_reflections.append(MissedReflection(reminder, window_end))
                                last_trigger_times[reminder.id] = window_end
                            else:
                                debug_file.write("  Outcome: Skipped (Delay Not Passed)\n")
                            debug_file.write("\n")
                else:
                    for i in range(len(heart_rate_data)):
                        current_sample = heart_rate_data[i]
                        window_end = current_sample['startDate']
                        window_start = window_end - timedelta(seconds=Interval.time_interval(reminder.interval))
                        
                        # Log window details
                        window_duration = (window_end - window_start).total_seconds()
                        debug_file.write(f"Window {i+1}:\n")
                        debug_file.write(f"  Start: {window_start}\n")
                        debug_file.write(f"  End: {window_end}\n")
                        debug_file.write(f"  Duration: {window_duration} seconds\n")
                        
                        # Collect samples in the window
                        window_samples = []
                        for j in range(i, -1, -1):
                            sample = heart_rate_data[j]
                            sample_time = sample['startDate']
                            if sample_time < window_start:
                                break
                            window_samples.append(sample)
                        
                        # Log samples
                        debug_file.write(f"  Number of Samples: {len(window_samples)}\n")
                        debug_file.write("  Samples:\n")
                        for sample in window_samples:
                            debug_file.write(f"    {sample['startDate']}: {sample['heartRate']} bpm\n")
                        
                        # Check threshold
                        exceeds_threshold = all(sample['heartRate'] > reminder.threshold for sample in window_samples)
                        debug_file.write(f"  Exceeds Threshold: {exceeds_threshold} (Threshold: {reminder.threshold} bpm)\n")
                        if not exceeds_threshold:
                            failing_samples = [sample for sample in window_samples if sample['heartRate'] <= reminder.threshold]
                            debug_file.write("  Failing Samples (below threshold):\n")
                            for sample in failing_samples:
                                debug_file.write(f"    {sample['startDate']}: {sample['heartRate']} bpm\n")
                        
                        # Check delay
                        if exceeds_threshold:
                            last_trigger = last_trigger_times[reminder.id]
                            delay = Interval.buffer(reminder.interval)
                            delay_passed = last_trigger is None or (window_end - last_trigger) >= delay
                            debug_file.write(f"  Delay Check:\n")
                            debug_file.write(f"    Last Trigger: {last_trigger}\n")
                            debug_file.write(f"    Delay: {delay}\n")
                            debug_file.write(f"    Delay Passed: {delay_passed}\n")
                            
                            if delay_passed:
                                debug_file.write("  Outcome: Reflection Triggered\n")
                                triggered_reflections.append(MissedReflection(reminder, window_end))
                                last_trigger_times[reminder.id] = window_end
                            else:
                                debug_file.write("  Outcome: Skipped (Delay Not Passed)\n")
                        else:
                            debug_file.write("  Outcome: Skipped (Threshold Not Met)\n")
                        
                        debug_file.write("\n")

    # Step 2: Post-Processing and Filtering

    # Partition by Measurement Type
    steps_reflections = [r for r in triggered_reflections if r.measurement_type == "Steps"]
    heart_rate_reflections = [r for r in triggered_reflections if r.measurement_type == "Heart Rate"]

    # Overlapping and Redundancy Filtering for Steps
    steps_reflections = filter_reflections(steps_reflections)

    # Overlapping and Redundancy Filtering for Heart Rate
    heart_rate_reflections = filter_reflections(heart_rate_reflections)

    # Combine the filtered reflections
    final_reflections = steps_reflections + heart_rate_reflections

    return final_reflections

def filter_reflections(reflections):
    """
    Filter reflections to keep all strong reflections and remove redundant non-strong reflections.

    Args:
        reflections (list): List of MissedReflection objects for a single measurement type.

    Returns:
        list: Filtered list of MissedReflection objects, sorted chronologically.
    """
    # Sort reflections chronologically by trigger date
    reflections.sort(key=lambda x: x.date)

    # Keep all strong reflections
    strong_reflections = [r for r in reflections if r.reminder_type == "Strong"]

    # Filter non-strong reflections (Medium/Light)
    non_strong_reflections = [r for r in reflections if r.reminder_type != "Strong"]
    filtered_non_strong = []
    last_trigger_time = None

    for reflection in non_strong_reflections:
        if last_trigger_time is None or (reflection.date - last_trigger_time) >= Interval.buffer(reflection.interval):
            filtered_non_strong.append(reflection)
            last_trigger_time = reflection.date

    # Combine strong and filtered non-strong reflections, maintaining chronological order
    return sorted(strong_reflections + filtered_non_strong, key=lambda x: x.date)

def trigger_contributing_samples(trigger):
    """
    Retrieve samples contributing to a missed reflection trigger.

    Loads step or heart rate data from JSON based on the trigger's measurement type.

    Args:
        trigger (MissedReflection): The trigger object.

    Returns:
        list: Contributing samples based on measurement type.

    Raises:
        FileNotFoundError: If the relevant JSON file is not found.
    """
    window_end = trigger.date
    if trigger.measurement_type == "Steps":
        step_file = Path('stepData.json')
        if not step_file.exists():
            raise FileNotFoundError("stepData.json not found in the current directory")
        with open(step_file, 'r') as f:
            step_data = json.load(f)
        for sample in step_data:
            sample['startDate'] = pd.to_datetime(sample['startDate']).to_pydatetime()
            sample['endDate'] = pd.to_datetime(sample['endDate']).to_pydatetime()
        
        if trigger.interval == Interval.ONE_DAY:
            return step_data
        window_start = window_end - timedelta(seconds=Interval.time_interval(trigger.interval))
        return [s for s in step_data if s['endDate'] <= window_end and s['startDate'] >= window_start]
    elif trigger.measurement_type == "Heart Rate":
        heart_rate_file = Path('heartRateData.json')
        if not heart_rate_file.exists():
            raise FileNotFoundError("heartRateData.json not found in the current directory")
        with open(heart_rate_file, 'r') as f:
            heart_rate_data = json.load(f)
        for sample in heart_rate_data:
            sample['startDate'] = pd.to_datetime(sample['startDate']).to_pydatetime()
            sample['endDate'] = pd.to_datetime(sample['endDate']).to_pydatetime()
        
        if trigger.interval == Interval.IMMEDIATELY:
            return [h for h in heart_rate_data if h['startDate'] == window_end]
        window_start = window_end - timedelta(seconds=Interval.time_interval(trigger.interval))
        return [h for h in heart_rate_data if h['startDate'] <= window_end and h['startDate'] >= window_start]