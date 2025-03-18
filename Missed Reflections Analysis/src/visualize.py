import sys
import json
import os
from datetime import datetime, timedelta
import matplotlib.pyplot as plt
from matplotlib.dates import DateFormatter, MinuteLocator, HourLocator
from .models import Reminder, ReminderType, Interval
from .missed_reflections_algorithm import check_missed_reflections, trigger_contributing_samples

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

with open('stepData.json', 'r') as f:
    step_data_json = json.load(f)

step_data = [
    {
        'stepCount': item['stepCount'],
        'startDate': datetime.strptime(item['startDate'], '%Y-%m-%dT%H:%M:%SZ'),
        'endDate': datetime.strptime(item['endDate'], '%Y-%m-%dT%H:%M:%SZ')
    }
    for item in step_data_json
]
step_data.sort(key=lambda x: x['startDate'])

def format_date(dt):
    return dt.strftime('%A %-d %B %Y at %-I:%M:%S %p')

print("Step Data (First 3 Samples):")
for data in step_data[:3]:
    print(f"Start: {format_date(data['startDate'])}")
    print(f"End: {format_date(data['endDate'])}")
    print(f"Steps: {data['stepCount']}")
    print("---")

reminders = [
    Reminder(measurement_type="Steps", reminder_type=ReminderType.LIGHT, threshold=500, interval=Interval.THIRTY_MINUTES),
    Reminder(measurement_type="Steps", reminder_type=ReminderType.LIGHT, threshold=1000, interval=Interval.ONE_HOUR),
    Reminder(measurement_type="Steps", reminder_type=ReminderType.MEDIUM, threshold=1000, interval=Interval.THIRTY_MINUTES),
    Reminder(measurement_type="Steps", reminder_type=ReminderType.MEDIUM, threshold=2000, interval=Interval.TWO_HOURS),
    Reminder(measurement_type="Steps", reminder_type=ReminderType.MEDIUM, threshold=3000, interval=Interval.FOUR_HOURS),
    Reminder(measurement_type="Steps", reminder_type=ReminderType.STRONG, threshold=1500, interval=Interval.ONE_HOUR),
    Reminder(measurement_type="Steps", reminder_type=ReminderType.STRONG, threshold=2500, interval=Interval.TWO_HOURS),
    Reminder(measurement_type="Steps", reminder_type=ReminderType.STRONG, threshold=4000, interval=Interval.FOUR_HOURS),
    Reminder(measurement_type="Steps", reminder_type=ReminderType.STRONG, threshold=5000, interval=Interval.ONE_DAY),
    Reminder(measurement_type="Steps", reminder_type=ReminderType.STRONG, threshold=10000, interval=Interval.ONE_DAY),
]

os.makedirs("Missed Reflections", exist_ok=True)
date_format = DateFormatter('%-I:%M %p')

all_triggers = check_missed_reflections(reminders, step_data)

# Sort triggers by window_start (trigger.date - interval)
all_triggers.sort(key=lambda x: x.date - timedelta(seconds=Interval.time_interval(x.interval)))

trigger_count = 0
for reminder in reminders:
    folder_name = f"Missed Reflections/{reminder.reminder_type}_{reminder.threshold}_{reminder.interval.replace(' ', '_')}"
    os.makedirs(folder_name, exist_ok=True)
    
    print(f"\nSteps Reminder Triggers ({reminder.trigger_summary}):")
    reminder_triggers = [t for t in all_triggers if t.reminder_type == reminder.reminder_type and 
                         t.threshold == reminder.threshold and t.interval == reminder.interval]
    for trigger in reminder_triggers:
        contributing_samples = trigger_contributing_samples(trigger, step_data)
        total_steps = sum(sample['stepCount'] for sample in contributing_samples)
        print(f"Triggered at: {format_date(trigger.date)}")
        print("Contributing samples within window:")
        for sample in contributing_samples:
            print(f"  {format_date(sample['startDate'])} - {format_date(sample['endDate'])}: {sample['stepCount']} steps")

for i, trigger in enumerate(all_triggers):
    folder_name = f"Missed Reflections/{trigger.reminder_type}_{trigger.threshold}_{trigger.interval.replace(' ', '_')}"
    
    plt.figure(figsize=(10, 6))
    
    window_start = trigger.date - timedelta(seconds=Interval.time_interval(trigger.interval)) if trigger.interval != Interval.ONE_DAY else min(sample['startDate'] for sample in step_data)
    buffer = Interval.buffer(trigger.interval)
    plot_start = window_start - buffer
    plot_end = trigger.date + buffer
    
    filtered_data = [s for s in step_data if plot_start <= s['startDate'] <= plot_end]
    filtered_times = [s['startDate'] for s in filtered_data]
    filtered_steps = [s['stepCount'] for s in filtered_data]
    contributing_samples = trigger_contributing_samples(trigger, step_data)
    total_steps = sum(sample['stepCount'] for sample in contributing_samples)
    
    plt.step(filtered_times, filtered_steps, where='post', color='green', label='Steps per Sample')
    plt.axvspan(window_start, trigger.date, color='yellow', alpha=0.3, label=f'Trigger Window ({trigger.interval})')
    plt.axhline(y=trigger.threshold, color='r', linestyle='--', label=f'Threshold ({trigger.threshold} steps)')
    
    plt.title(f"Missed Reflection: {trigger.trigger_summary}\nTotal Steps in Window: {total_steps}")
    plt.xlabel('Time')
    plt.ylabel('Steps')
    plt.legend()
    plt.xticks(rotation=45)
    plt.gca().xaxis.set_major_formatter(date_format)
    if trigger.interval == Interval.ONE_DAY:
        plt.gca().xaxis.set_major_locator(HourLocator(interval=1))
    else:
        plt.gca().xaxis.set_major_locator(MinuteLocator(interval=15))
    plt.xlim(plot_start, plot_end)
    
    filename = f"{folder_name}/missed_reflection_{i+1}_{trigger.date.strftime('%Y%m%d_%H%M%S')}.png"
    plt.tight_layout()
    plt.savefig(filename, dpi=300, bbox_inches='tight')
    plt.close()
    trigger_count += 1

print(f"\nGenerated {trigger_count} visualization(s) in 'Missed Reflections' subfolders")