import json
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from matplotlib.dates import DateFormatter, MinuteLocator, HourLocator
from matplotlib.ticker import MaxNLocator
import os
from datetime import timedelta

# Load data
with open('heartRateData.json', 'r') as f:
    heart_rate_data = json.load(f)

with open('stepData.json', 'r') as f:
    step_data = json.load(f)

# Convert to DataFrames
heart_rate_df = pd.DataFrame(heart_rate_data)
step_df = pd.DataFrame(step_data)

# Convert dates
heart_rate_df['startDate'] = pd.to_datetime(heart_rate_df['startDate'])
step_df['startDate'] = pd.to_datetime(step_df['startDate'])
step_df['endDate'] = pd.to_datetime(step_df['endDate'])

# Calculate differences and cumulative steps
heart_rate_df['time_diff'] = heart_rate_df['startDate'].diff().dt.total_seconds().fillna(0)
step_df['time_diff'] = step_df['startDate'].diff().dt.total_seconds().fillna(0)
step_df['cumulative_steps'] = step_df['stepCount'].cumsum()
step_df['window_duration'] = (step_df['endDate'] - step_df['startDate']).dt.total_seconds() / 60  # Duration in minutes

# Plot settings
sns.set_palette("deep")
date_format = DateFormatter('%A %-I:%M %p')

# Define periods
periods = {
    '1_hour': timedelta(hours=1),
    '2_hours': timedelta(hours=2),
    '1_day': timedelta(days=1)
}

def filter_by_period(df, start_col, period_delta):
    min_date = df[start_col].min()
    max_date = min_date + period_delta
    return df[df[start_col] <= max_date]

# Base folder
base_folder = 'Visualisations'
os.makedirs(base_folder, exist_ok=True)

# Subfolders
heart_rate_folder = os.path.join(base_folder, 'Heart_Rate')
steps_folder = os.path.join(base_folder, 'Steps')
os.makedirs(heart_rate_folder, exist_ok=True)
os.makedirs(steps_folder, exist_ok=True)

for period_name, period_delta in periods.items():
    # Period-specific subfolders
    hr_period_folder = os.path.join(heart_rate_folder, period_name)
    step_period_folder = os.path.join(steps_folder, period_name)
    os.makedirs(hr_period_folder, exist_ok=True)
    os.makedirs(step_period_folder, exist_ok=True)
    
    hr_period_df = filter_by_period(heart_rate_df, 'startDate', period_delta)
    step_period_df = filter_by_period(step_df, 'startDate', period_delta)
    
    tick_locator = MinuteLocator(interval=15) if period_name != '1_day' else HourLocator(interval=1)
    
    # Heart Rate Plots
    plt.figure(figsize=(10, 6))
    sns.histplot(data=hr_period_df, x='startDate', bins=30)
    plt.title('Heart Rate Sample Frequency Over Time')
    plt.xlabel('Time')
    plt.ylabel('Number of Samples')
    plt.xticks(rotation=45)
    plt.gca().xaxis.set_major_formatter(date_format)
    plt.gca().xaxis.set_major_locator(tick_locator)
    plt.gca().yaxis.set_major_locator(MaxNLocator(integer=True))
    plt.tight_layout()
    plt.savefig(os.path.join(hr_period_folder, 'heart_rate_frequency.png'), dpi=300, bbox_inches='tight')
    plt.close()
    
    plt.figure(figsize=(10, 6))
    sns.histplot(data=hr_period_df, x='time_diff', bins=50)
    plt.title('Distribution of Intervals Between Heart Rate Samples')
    plt.xlabel('Interval (seconds)')
    plt.ylabel('Count')
    plt.xlim(0, hr_period_df['time_diff'].quantile(0.95))
    plt.gca().yaxis.set_major_locator(MaxNLocator(integer=True))
    plt.tight_layout()
    plt.savefig(os.path.join(hr_period_folder, 'heart_rate_intervals.png'), dpi=300, bbox_inches='tight')
    plt.close()
    
    plt.figure(figsize=(10, 6))
    plt.plot(hr_period_df['startDate'], hr_period_df['heartRate'], 'b-', label='Heart Rate')
    plt.axhline(y=80, color='r', linestyle='--', label='Threshold (80 bpm)')
    plt.title('Heart Rate Values Over Time')
    plt.xlabel('Time')
    plt.ylabel('Heart Rate (bpm)')
    plt.legend()
    plt.xticks(rotation=45)
    plt.gca().xaxis.set_major_formatter(date_format)
    plt.gca().xaxis.set_major_locator(tick_locator)
    plt.tight_layout()
    plt.savefig(os.path.join(hr_period_folder, 'heart_rate_values.png'), dpi=300, bbox_inches='tight')
    plt.close()
    
    # Step Plots
    plt.figure(figsize=(10, 6))
    sns.histplot(data=step_period_df, x='startDate', bins=30)
    plt.title('Step Sample Frequency Over Time')
    plt.xlabel('Time')
    plt.ylabel('Number of Samples')
    plt.xticks(rotation=45)
    plt.gca().xaxis.set_major_formatter(date_format)
    plt.gca().xaxis.set_major_locator(tick_locator)
    plt.gca().yaxis.set_major_locator(MaxNLocator(integer=True))
    plt.tight_layout()
    plt.savefig(os.path.join(step_period_folder, 'step_frequency.png'), dpi=300, bbox_inches='tight')
    plt.close()
    
    plt.figure(figsize=(10, 6))
    sns.histplot(data=step_period_df, x='time_diff', bins=50)
    plt.title('Distribution of Intervals Between Step Samples')
    plt.xlabel('Interval (seconds)')
    plt.ylabel('Count')
    plt.xlim(0, step_period_df['time_diff'].quantile(0.95))
    plt.gca().yaxis.set_major_locator(MaxNLocator(integer=True))
    plt.tight_layout()
    plt.savefig(os.path.join(step_period_folder, 'step_intervals.png'), dpi=300, bbox_inches='tight')
    plt.close()
    
    plt.figure(figsize=(10, 6))
    plt.plot(step_period_df['endDate'], step_period_df['cumulative_steps'], 'g-', label='Cumulative Steps')
    plt.axhline(y=2000, color='r', linestyle='--', label='Threshold (2000 steps)')
    plt.title('Cumulative Steps Over Time')
    plt.xlabel('Time')
    plt.ylabel('Total Steps')
    plt.legend()
    plt.xticks(rotation=45)
    plt.gca().xaxis.set_major_formatter(date_format)
    plt.gca().xaxis.set_major_locator(tick_locator)
    plt.tight_layout()
    plt.savefig(os.path.join(step_period_folder, 'cumulative_steps.png'), dpi=300, bbox_inches='tight')
    plt.close()
    
    plt.figure(figsize=(10, 6))
    plt.plot(step_period_df['startDate'], step_period_df['stepCount'], 'g-', label='Steps per Sample')
    plt.title('Step Counts Over Time')
    plt.xlabel('Time')
    plt.ylabel('Steps')
    plt.legend()
    plt.xticks(rotation=45)
    plt.gca().xaxis.set_major_formatter(date_format)
    plt.gca().xaxis.set_major_locator(tick_locator)
    plt.tight_layout()
    plt.savefig(os.path.join(step_period_folder, 'step_counts_time_series.png'), dpi=300, bbox_inches='tight')
    plt.close()
    
    plt.figure(figsize=(10, 6))
    for i in range(len(step_period_df)):
        plt.bar(step_period_df['startDate'].iloc[i], step_period_df['stepCount'].iloc[i], 
                width=step_period_df['window_duration'].iloc[i]/(24*60), align='edge', color='green', alpha=0.7)
    plt.title('Step Counts with Window Durations')
    plt.xlabel('Time')
    plt.ylabel('Steps')
    plt.xticks(rotation=45)
    plt.gca().xaxis.set_major_formatter(date_format)
    plt.gca().xaxis.set_major_locator(tick_locator)
    plt.tight_layout()
    plt.savefig(os.path.join(step_period_folder, 'step_window_duration.png'), dpi=300, bbox_inches='tight')
    plt.close()

# Statistics in minutes
hr_total_samples = len(heart_rate_df)
hr_avg_interval = heart_rate_df['time_diff'].mean() / 60
hr_min_interval = heart_rate_df['time_diff'].min() / 60
hr_max_interval = heart_rate_df['time_diff'].max() / 60

step_total_samples = len(step_df)
step_avg_interval = step_df['time_diff'].mean() / 60
step_min_interval = step_df['time_diff'].min() / 60
step_max_interval = step_df['time_diff'].max() / 60

# Print statistics
print("Heart Rate Data Statistics:")
print(f"Total samples: {hr_total_samples}")
print(f"Average interval between samples: {hr_avg_interval:.2f} minutes")
print(f"Min interval: {hr_min_interval:.2f} minutes")
print(f"Max interval: {hr_max_interval:.2f} minutes")

print("\nStep Data Statistics:")
print(f"Total samples: {step_total_samples}")
print(f"Average interval between samples: {step_avg_interval:.2f} minutes")
print(f"Min interval: {step_min_interval:.2f} minutes")
print(f"Max interval: {step_max_interval:.2f} minutes")

# Create statistics image
plt.figure(figsize=(8, 6))
plt.text(0.1, 0.9, "Heart Rate Data Statistics:", fontsize=14, fontweight='bold')
plt.text(0.1, 0.85, f"Total samples: {hr_total_samples}", fontsize=12)
plt.text(0.1, 0.80, f"Average interval between samples: {hr_avg_interval:.2f} minutes", fontsize=12)
plt.text(0.1, 0.75, f"Min interval: {hr_min_interval:.2f} minutes", fontsize=12)
plt.text(0.1, 0.70, f"Max interval: {hr_max_interval:.2f} minutes", fontsize=12)

plt.text(0.1, 0.6, "Step Data Statistics:", fontsize=14, fontweight='bold')
plt.text(0.1, 0.55, f"Total samples: {step_total_samples}", fontsize=12)
plt.text(0.1, 0.50, f"Average interval between samples: {step_avg_interval:.2f} minutes", fontsize=12)
plt.text(0.1, 0.45, f"Min interval: {step_min_interval:.2f} minutes", fontsize=12)
plt.text(0.1, 0.40, f"Max interval: {step_max_interval:.2f} minutes", fontsize=12)

plt.axis('off')  # No axes for a text-only image
plt.savefig(os.path.join(base_folder, 'statistics.png'), dpi=300, bbox_inches='tight')
plt.close()

print("\nVisualizations saved in 'Visualisations' folder with subfolders: Heart_Rate, Steps")
print("Statistics image saved as 'Visualisations/statistics.png'")