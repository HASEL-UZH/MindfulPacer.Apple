from datetime import timedelta
from .models import Interval, MissedReflection

def check_missed_reflections(reminders, step_data):
    """
    Detect missed reflections based on step data and a list of reminders with a delay mechanism.

    This function evaluates an array of Reminder objects against a list of step data to identify
    instances where a step threshold is exceeded within specified intervals. It includes a delay
    mechanism to prevent multiple triggers within a short timeframe of a previous trigger for
    the same reminder, enhancing the reliability of alerts.

    For each reminder, the algorithm handles two scenarios:
    - For a '1 Day' interval, it calculates the total steps across the entire dataset (assumed
      to span the last 24 hours) and triggers a reflection if the total exceeds the threshold,
      using the earliest start date and latest end date as the window. No delay is applied
      for '1 Day' as it represents a single full-day assessment.
    - For all other intervals (30 Minutes, 1 Hour, 2 Hours, 4 Hours), it applies a sliding
      window approach, moving through the step data chronologically by end date. For each
      sample, it sums the step counts within the reminder's interval (e.g., 4 hours back
      from the current sample's end date) and triggers a reflection if the sum exceeds the
      threshold, provided the new trigger is at least a configurable delay after the last
      trigger for that reminder.

    Args:
        reminders (list): A list of Reminder objects, each specifying a measurement type
                         (Steps), reminder type (Light, Medium, Strong), threshold (int),
                         and interval (e.g., '30 Minutes', '1 Day').
        step_data (list): A list of dictionaries, each containing 'stepCount' (int),
                         'startDate' (datetime), and 'endDate' (datetime) for step samples.

    Returns:
        list: A list of MissedReflection objects, each representing a time when the step
              threshold was exceeded, with the trigger date set to the window's end time,
              filtered by the delay constraint.
    """
    triggered_reflections = []
    last_trigger_times = {reminder.id: None for reminder in reminders}
    DELAY_MAPPING = {
        Interval.THIRTY_MINUTES: timedelta(minutes=5),
        Interval.ONE_HOUR: timedelta(minutes=15),
        Interval.TWO_HOURS: timedelta(minutes=15),
        Interval.FOUR_HOURS: timedelta(minutes=30),
        Interval.ONE_DAY: timedelta(minutes=0)
    }
    
    for reminder in reminders:
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
                    delay = DELAY_MAPPING[reminder.interval]
                    if last_trigger is None or (window_end - last_trigger) >= delay:
                        triggered_reflections.append(MissedReflection(reminder, window_end))
                        last_trigger_times[reminder.id] = window_end
    
    return triggered_reflections

def trigger_contributing_samples(trigger, step_data):
    """
    Retrieve the step samples contributing to a missed reflection trigger.

    This function identifies the step data samples that fall within the time window
    defined by a given MissedReflection object. For '1 Day' intervals, it returns the
    entire dataset (assumed to be within 24 hours). For other intervals, it filters
    samples where the end date is on or before the trigger date and the start date
    is on or after the start of the interval window.

    Args:
        trigger (MissedReflection): A MissedReflection object containing the reminder
                                   details and trigger date.
        step_data (list): A list of dictionaries with 'stepCount', 'startDate', and
                         'endDate' for step samples.

    Returns:
        list: A list of step data dictionaries that contribute to the trigger.
    """
    window_end = trigger.date
    if trigger.interval == Interval.ONE_DAY:
        return step_data
    window_start = window_end - timedelta(seconds=Interval.time_interval(trigger.interval))
    return [s for s in step_data if s['endDate'] <= window_end and s['startDate'] >= window_start]