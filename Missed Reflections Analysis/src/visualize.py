import sys
import json
import os
from datetime import datetime, timedelta
import matplotlib.pyplot as plt
from matplotlib.dates import DateFormatter, MinuteLocator
from tqdm import tqdm
from .models import Reminder, ReminderType, Interval
from .missed_reflections_algorithm import check_missed_reflections, trigger_contributing_samples

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

# Load and preprocess step data
with open('stepData.json', 'r') as f:
    step_data_json = json.load(f)

step_data = [
    {
        'stepCount': item['stepCount'],
        'startDate': datetime.fromisoformat(item['startDate'].replace('Z', '+00:00')),
        'endDate': datetime.fromisoformat(item['endDate'].replace('Z', '+00:00'))
    }
    for item in step_data_json
]
step_data.sort(key=lambda x: x['startDate'])

# Load and preprocess heart rate data
with open('heartRateData.json', 'r') as f:
    heart_rate_data_json = json.load(f)

heart_rate_data = [
    {
        'heartRate': item['heartRate'],
        'startDate': datetime.fromisoformat(item['startDate'].replace('Z', '+00:00')),
        'endDate': datetime.fromisoformat(item['endDate'].replace('Z', '+00:00'))
    }
    for item in heart_rate_data_json
]
heart_rate_data.sort(key=lambda x: x['startDate'])

# Define reminders for both steps and heart rate
reminders = [
    # Step reminders
    # Reminder(measurement_type="Steps", reminder_type=ReminderType.LIGHT, threshold=500, interval=Interval.THIRTY_MINUTES),
    # Reminder(measurement_type="Steps", reminder_type=ReminderType.LIGHT, threshold=1000, interval=Interval.ONE_HOUR),
    # Reminder(measurement_type="Steps", reminder_type=ReminderType.MEDIUM, threshold=1000, interval=Interval.THIRTY_MINUTES),
    # Reminder(measurement_type="Steps", reminder_type=ReminderType.MEDIUM, threshold=2000, interval=Interval.TWO_HOURS),
    # Reminder(measurement_type="Steps", reminder_type=ReminderType.MEDIUM, threshold=3000, interval=Interval.FOUR_HOURS),
    # Reminder(measurement_type="Steps", reminder_type=ReminderType.STRONG, threshold=1500, interval=Interval.ONE_HOUR),
    # Reminder(measurement_type="Steps", reminder_type=ReminderType.STRONG, threshold=2500, interval=Interval.TWO_HOURS),
    # Reminder(measurement_type="Steps", reminder_type=ReminderType.STRONG, threshold=4000, interval=Interval.FOUR_HOURS),
    # Reminder(measurement_type="Steps", reminder_type=ReminderType.STRONG, threshold=5000, interval=Interval.ONE_DAY),
    # Reminder(measurement_type="Steps", reminder_type=ReminderType.STRONG, threshold=10000, interval=Interval.ONE_DAY),
    # Heart rate reminders
    Reminder(measurement_type="Heart Rate", reminder_type=ReminderType.STRONG, threshold=90, interval=Interval.FIVE_MINUTES),
    Reminder(measurement_type="Heart Rate", reminder_type=ReminderType.MEDIUM, threshold=75, interval=Interval.TEN_MINUTES),
    Reminder(measurement_type="Heart Rate", reminder_type=ReminderType.LIGHT, threshold=65, interval=Interval.FIFTEEN_MINUTES)
]

os.makedirs("Missed Reflections/Steps", exist_ok=True)
os.makedirs("Missed Reflections/Heart Rate", exist_ok=True)
date_format = DateFormatter('%-I:%M %p')

# Get all triggers
all_triggers = check_missed_reflections(reminders)

# Sort triggers by window_start (trigger.date - interval)
all_triggers.sort(key=lambda x: x.date - timedelta(seconds=Interval.time_interval(x.interval)))

# Generate visualizations with tqdm progress bar
trigger_count = 0
for i, trigger in enumerate(tqdm(all_triggers, desc="Generating Visualizations")):
    base_folder = "Missed Reflections/Steps" if trigger.measurement_type == "Steps" else "Missed Reflections/Heart Rate"
    folder_name = f"{base_folder}/{trigger.reminder_type}_{trigger.threshold}_{trigger.interval.replace(' ', '_')}"
    os.makedirs(folder_name, exist_ok=True)
    
    plt.figure(figsize=(10, 6))
    
    if trigger.measurement_type == "Steps":
        window_start = trigger.date - timedelta(seconds=Interval.time_interval(trigger.interval)) if trigger.interval != Interval.ONE_DAY else min(sample['startDate'] for sample in step_data)
        buffer = Interval.buffer(trigger.interval)
        plot_start = window_start - buffer
        plot_end = trigger.date + buffer
        
        filtered_data = [s for s in step_data if plot_start <= s['startDate'] <= plot_end]
        filtered_times = [s['startDate'] for s in filtered_data]
        filtered_steps = [s['stepCount'] for s in filtered_data]
        contributing_samples = trigger_contributing_samples(trigger)
        total_steps = sum(sample['stepCount'] for sample in contributing_samples)
        
        plt.step(filtered_times, filtered_steps, where='post', color='green', label='Steps per Sample')
        plt.axvspan(window_start, trigger.date, color='yellow', alpha=0.3, label=f'Trigger Window ({trigger.interval})')
        plt.axhline(y=trigger.threshold, color='r', linestyle='--', label=f'Threshold ({trigger.threshold} steps)')
        
        plt.title(f"Missed Reflection: {trigger.trigger_summary}\nTotal Steps in Window: {total_steps}")
        plt.xlabel('Time')
        plt.ylabel('Steps')
    
    elif trigger.measurement_type == "Heart Rate":
        window_start = trigger.date - timedelta(seconds=Interval.time_interval(trigger.interval)) if trigger.interval != Interval.IMMEDIATELY else trigger.date
        buffer = Interval.buffer(trigger.interval)
        plot_start = window_start - buffer
        plot_end = trigger.date + buffer
        
        filtered_data = [h for h in heart_rate_data if plot_start <= h['startDate'] <= plot_end]
        filtered_times = [h['startDate'] for h in filtered_data]
        filtered_hr = [h['heartRate'] for h in filtered_data]
        contributing_samples = trigger_contributing_samples(trigger)
        
        plt.plot(filtered_times, filtered_hr, 'b-', label='Heart Rate')
        if trigger.interval != Interval.IMMEDIATELY:
            plt.axvspan(window_start, trigger.date, color='yellow', alpha=0.3, label=f'Trigger Window ({trigger.interval})')
        plt.axhline(y=trigger.threshold, color='r', linestyle='--', label=f'Threshold ({trigger.threshold} bpm)')
        
        plt.title(f"Missed Reflection: {trigger.trigger_summary}")
        plt.xlabel('Time')
        plt.ylabel('Heart Rate (bpm)')
    
    plt.legend()
    plt.xticks(rotation=45)
    plt.gca().xaxis.set_major_formatter(date_format)
    # Set x-axis ticks to every 3 minutes for all intervals
    plt.gca().xaxis.set_major_locator(MinuteLocator(interval=3))
    plt.xlim(plot_start, plot_end)
    
    filename = f"{folder_name}/missed_reflection_{i+1}_{trigger.date.strftime('%Y%m%d_%H%M%S')}.png"
    plt.tight_layout()
    plt.savefig(filename, dpi=300, bbox_inches='tight')
    plt.close()
    trigger_count += 1

print(f"\nGenerated {trigger_count} visualization(s) in 'Missed Reflections' subfolders")