import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from datetime import datetime, timedelta
import pytz # For timezone conversion
import re # For parsing reminder messages

# --- Configuration ---
HR_DENSE_LOG_FILE = "mindfulpacer_hr_dense_log.csv"
SERVICE_EVENT_LOG_FILE = "mindfulpacer_hr_service_log.txt"
GAP_THRESHOLD_SECONDS = 15
# EXPECTED_SAMPLING_RATE_SECONDS = 2 # Less critical for current uptime calculation

def parse_iso_timestamp(ts_str):
    """Safely parses ISO timestamp string, trying multiple formats."""
    formats_to_try = [
        '%Y-%m-%dT%H:%M:%S.%fZ', # With microseconds
        '%Y-%m-%dT%H:%M:%SZ',    # Without microseconds
    ]
    if '.' in ts_str: # Pre-process to ensure 6 digits for microseconds if present
        parts = ts_str.split('.')
        if len(parts) == 2:
            frac_seconds = parts[1].replace('Z','')
            if len(frac_seconds) > 6:
                ts_str = parts[0] + '.' + frac_seconds[:6] + 'Z'
            elif len(frac_seconds) < 6:
                 ts_str = parts[0] + '.' + frac_seconds.ljust(6, '0') + 'Z'


    for fmt in formats_to_try:
        try:
            return pd.to_datetime(ts_str, format=fmt, utc=True, errors='raise')
        except ValueError:
            continue
    print(f"Warning: Could not parse timestamp '{ts_str}' with known formats.")
    return pd.NaT

def load_hr_dense_log(filepath=HR_DENSE_LOG_FILE):
    """Loads and parses the dense HR sample log."""
    try:
        df = pd.read_csv(filepath, header=None, names=['timestamp_str', 'bpm_str'])
        df['timestamp'] = df['timestamp_str'].apply(parse_iso_timestamp)
        df['bpm'] = pd.to_numeric(df['bpm_str'], errors='coerce')
        df.dropna(subset=['timestamp', 'bpm'], inplace=True)
        if df.empty:
            print(f"No valid data after parsing in {filepath}")
            return pd.DataFrame(columns=['bpm']).set_index(pd.to_datetime([], utc=True))
        df.set_index('timestamp', inplace=True)
        if not df.index.is_unique:
            print("Warning: HR DataFrame index contains duplicate timestamps. Aggregating by taking the mean BPM.")
            df = df.groupby(df.index).mean()
        df.sort_index(inplace=True)
        print(f"Successfully loaded and processed {len(df)} HR samples from {filepath}")
        return df
    except FileNotFoundError:
        print(f"Error: Dense HR log file '{filepath}' not found.")
        return pd.DataFrame(columns=['bpm']).set_index(pd.to_datetime([], utc=True))
    except Exception as e:
        print(f"Error loading dense HR log '{filepath}': {e}")
        return pd.DataFrame(columns=['bpm']).set_index(pd.to_datetime([], utc=True))

def load_service_event_log(filepath=SERVICE_EVENT_LOG_FILE):
    """Loads and parses the service event log."""
    events = []
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            for i, line in enumerate(f):
                parts = line.strip().split(' | ', 2)
                if len(parts) == 3:
                    ts_str = parts[0].strip()
                    event_type = parts[1].strip()
                    message = parts[2].strip()
                    ts = parse_iso_timestamp(ts_str)
                    if pd.notna(ts):
                        events.append({'timestamp': ts, 'event_type': event_type, 'message': message})
                    else:
                        print(f"Warning: Skipped event line {i+1} due to unparsable timestamp: {line.strip()}")
                elif line.strip():
                    print(f"Warning: Malformed event log line {i+1}: {line.strip()}")
        df = pd.DataFrame(events)
        if not df.empty:
            df.set_index('timestamp', inplace=True)
            if not df.index.is_unique:
                print(f"Warning: Service event DataFrame index is not unique. Keeping first entry for duplicate timestamps.")
                df = df[~df.index.duplicated(keep='first')]
            df.sort_index(inplace=True)
        print(f"Successfully loaded and processed {len(df)} service events from {filepath}")
        return df
    except FileNotFoundError:
        print(f"Error: Service event log file '{filepath}' not found.")
        return pd.DataFrame(columns=['event_type', 'message']).set_index(pd.to_datetime([], utc=True))
    except Exception as e:
        print(f"Error loading service event log '{filepath}': {e}")
        return pd.DataFrame(columns=['event_type', 'message']).set_index(pd.to_datetime([], utc=True))

def analyze_hr_continuity(hr_df):
    if hr_df.empty or len(hr_df) < 2:
        print("HR data is empty or insufficient for continuity analysis.")
        return None, pd.Series(dtype='float64')

    hr_df_sorted = hr_df.sort_index()
    hr_df_sorted['time_diff_seconds'] = hr_df_sorted.index.to_series().diff().dt.total_seconds()
    gaps = hr_df_sorted[hr_df_sorted['time_diff_seconds'] > GAP_THRESHOLD_SECONDS]
    
    print("\n--- HR Monitoring Continuity Analysis ---")
    total_duration_seconds = (hr_df_sorted.index.max() - hr_df_sorted.index.min()).total_seconds() if not hr_df_sorted.empty else 0

    if total_duration_seconds > 0:
        print(f"Total observation span: {timedelta(seconds=int(total_duration_seconds))}")
        actual_time_in_gaps = gaps['time_diff_seconds'].sum()
        
        # A simple way to estimate uptime is total span MINUS the DURATION of the gaps.
        # Each 'time_diff_seconds' in gaps IS the duration of that gap.
        monitoring_duration_seconds = total_duration_seconds - actual_time_in_gaps
        
        # If you want to subtract only the "excess" time beyond a normal interval:
        # Assuming a normal interval of e.g., 2 seconds.
        # excess_gap_time = (gaps['time_diff_seconds'] - EXPECTED_SAMPLING_RATE_SECONDS).clip(lower=0).sum()
        # monitoring_duration_seconds = total_duration_seconds - excess_gap_time
        
        monitoring_duration_seconds = max(0, min(monitoring_duration_seconds, total_duration_seconds))
        uptime_percentage = (monitoring_duration_seconds / total_duration_seconds) * 100 if total_duration_seconds > 0 else 0

        print(f"Number of gaps (>{GAP_THRESHOLD_SECONDS}s): {len(gaps)}")
        print(f"Total time duration of identified gaps: {timedelta(seconds=int(actual_time_in_gaps))}")
        print(f"Estimated monitoring uptime (Total Span - Sum of Gap Durations): {timedelta(seconds=int(monitoring_duration_seconds))} ({uptime_percentage:.2f}%)")

        if not gaps.empty:
            print("\nDetected Gaps (gap starts after previous sample, ends at current sample's timestamp):")
            for timestamp, row in gaps.iterrows():
                gap_start_time = timestamp - pd.Timedelta(seconds=row['time_diff_seconds'])
                print(f"  Gap from ~{gap_start_time.tz_convert('Europe/Zurich').strftime('%Y-%m-%d %H:%M:%S %Z')} to {timestamp.tz_convert('Europe/Zurich').strftime('%Y-%m-%d %H:%M:%S %Z')} (Duration: {pd.Timedelta(seconds=row['time_diff_seconds'])})")
    else:
        print("Not enough data or no significant gaps found for detailed continuity analysis.")
    return gaps, hr_df_sorted['time_diff_seconds'].dropna()

def plot_hr_data(hr_df, event_df, gaps_df):
    if hr_df.empty:
        print("No HR data to plot.")
        return

    swiss_tz = pytz.timezone('Europe/Zurich')
    hr_df_local = hr_df.tz_convert(swiss_tz)
    event_df_local = event_df.tz_convert(swiss_tz) if not event_df.empty else event_df
    gaps_df_local = gaps_df.tz_convert(swiss_tz) if gaps_df is not None and not gaps_df.empty else gaps_df

    fig, ax = plt.subplots(figsize=(18, 9))
    main_hr_line, = ax.plot(hr_df_local.index, hr_df_local['bpm'], label='Heart Rate (BPM)', color='cornflowerblue', linewidth=1.5, marker='.', markersize=3, alpha=0.7)
    
    if gaps_df_local is not None and not gaps_df_local.empty:
        for timestamp, row in gaps_df_local.iterrows():
            gap_start_time = timestamp - pd.Timedelta(seconds=row['time_diff_seconds'])
            ax.axvspan(gap_start_time, timestamp, color='salmon', alpha=0.3, label='_nolegend_')

    reminder_events_local = event_df_local[event_df_local['event_type'] == 'REMINDER_TRIGGERED']
    plot_reminder_x_markers = []
    plot_reminder_y_markers = []

    if not reminder_events_local.empty:
        print("\n--- Processing Reminder Triggers for Plot ---")
        for reminder_idx_local, reminder_row in reminder_events_local.iterrows():
            message = reminder_row['message']
            # Regex to find WindowStart and Now timestamps
            match = re.search(r"WindowStart=([\dT.:\-Z]+).*Now=([\dT.:\-Z]+)", message)
            if match:
                window_start_str, window_end_str = match.groups()
                window_start_utc = parse_iso_timestamp(window_start_str)
                window_end_utc = parse_iso_timestamp(window_end_str)

                if pd.notna(window_start_utc) and pd.notna(window_end_utc):
                    window_start_local = window_start_utc.tz_convert(swiss_tz)
                    window_end_local = window_end_utc.tz_convert(swiss_tz)
                    ax.axvspan(window_start_local, window_end_local, color='green', alpha=0.4, zorder=0, label='_nolegend_')
                    print(f"Shaded reminder window: {window_start_local.strftime('%H:%M:%S')} - {window_end_local.strftime('%H:%M:%S')}")
                else:
                    print(f"Warning: Could not parse window timestamps from reminder message: {message}")
            else:
                 print(f"Warning: Could not find WindowStart/Now in reminder message: {message}")


            # For scatter marker at the reminder event time itself
            closest_hr_ts_utc = hr_df.index.asof(reminder_idx_local.tz_convert('UTC'))
            if pd.notna(closest_hr_ts_utc) and abs((reminder_idx_local.tz_convert('UTC') - closest_hr_ts_utc).total_seconds()) < 10:
                bpm_value = hr_df.loc[closest_hr_ts_utc, 'bpm']
                if pd.notna(bpm_value):
                    plot_reminder_x_markers.append(closest_hr_ts_utc.tz_convert(swiss_tz))
                    plot_reminder_y_markers.append(bpm_value)
            else:
                print(f"Warning: No close HR data point for reminder marker at {reminder_idx_local}. Skipping marker point.")
        
        if plot_reminder_x_markers:
            ax.scatter(plot_reminder_x_markers, plot_reminder_y_markers,
                       color='magenta', marker='X', s=150, edgecolor='black', zorder=5, label='_nolegend_')
        else:
            print("No reminder event markers could be plotted.")

    service_start_events_local = event_df_local[event_df_local['message'].str.contains("Starting HR monitoring", case=False, na=False)]
    service_stop_events_local = event_df_local[event_df_local['message'].str.contains("Stopping HR monitoring", case=False, na=False)]
    
    for t_start in service_start_events_local.index:
        ax.axvline(t_start, color='green', linestyle='--', linewidth=1.5, label='_nolegend_')
    for t_stop in service_stop_events_local.index:
        ax.axvline(t_stop, color='darkorange', linestyle='--', linewidth=1.5, label='_nolegend_')

    legend_handles = [main_hr_line]
    if not service_start_events_local.empty:
        legend_handles.append(plt.Line2D([0], [0], color='green', linestyle='--', lw=1.5, label='Service Start'))
    if not service_stop_events_local.empty:
        legend_handles.append(plt.Line2D([0], [0], color='darkorange', linestyle='--', lw=1.5, label='Service Stop'))
    if gaps_df is not None and not gaps_df.empty:
         legend_handles.append(plt.Rectangle((0,0),1,1, facecolor='salmon', alpha=0.3, label=f'Gap > {GAP_THRESHOLD_SECONDS}s'))
    if plot_reminder_x_markers:
        legend_handles.append(plt.Line2D([0], [0], marker='X', color='w', markerfacecolor='magenta', markeredgecolor='black', markersize=10, label='Reminder Triggered (at time of event)'))
    if not reminder_events_local.empty: # Add legend for shaded window if any reminder occurred
        legend_handles.append(plt.Rectangle((0,0),1,1, facecolor='lightgoldenrodyellow', alpha=0.4, label='Reminder Window (5 min)'))


    ax.set_title('Heart Rate Monitoring Over Time (Local Time: Europe/Zurich)', fontsize=16)
    ax.set_xlabel('Time (HH:MM:SS)', fontsize=12)
    ax.set_ylabel('Heart Rate (BPM)', fontsize=12)
    
    ax.legend(handles=legend_handles, fontsize=10, loc='upper left')
    ax.grid(True, which='major', linestyle='-.', linewidth=0.5, alpha=0.7)
    ax.grid(True, which='minor', linestyle=':', linewidth=0.3, alpha=0.5)
    
    ax.xaxis.set_major_formatter(mdates.DateFormatter('%H:%M:%S', tz=swiss_tz))
    ax.xaxis.set_minor_locator(mdates.SecondLocator(interval=60 * 5)) # Minor ticks every 5 mins
    ax.xaxis.set_major_locator(mdates.MinuteLocator(interval=30)) # Major labels every 30 mins
    fig.autofmt_xdate(rotation=30, ha='right')
    
    plt.tight_layout()
    plt.savefig("hr_monitoring_plot.png")
    print("\nPlot saved as hr_monitoring_plot.png")
    plt.show()

def plot_sampling_intervals(time_diffs_series):
    # ... (function remains the same)
    if time_diffs_series.empty or time_diffs_series.isnull().all():
        print("No valid time differences to plot for sampling intervals.")
        return
        
    plt.figure(figsize=(12, 7))
    valid_intervals = time_diffs_series[time_diffs_series <= GAP_THRESHOLD_SECONDS * 2] 
    if valid_intervals.empty:
        print(f"No sampling intervals less than or equal to {GAP_THRESHOLD_SECONDS*2}s found.")
        return

    n_bins = min(50, len(valid_intervals.unique())) if len(valid_intervals.unique()) > 1 else 10
    plt.hist(valid_intervals, bins=n_bins, color='skyblue', edgecolor='black', alpha=0.7)
    
    mean_interval = valid_intervals.mean()
    median_interval = valid_intervals.median()
    mode_interval = valid_intervals.mode()
    mode_interval_val = mode_interval[0] if not mode_interval.empty else float('nan')

    plt.axvline(mean_interval, color='red', linestyle='dashed', linewidth=1.5, label=f'Mean: {mean_interval:.2f}s')
    plt.axvline(median_interval, color='green', linestyle='dashed', linewidth=1.5, label=f'Median: {median_interval:.2f}s')
    if pd.notna(mode_interval_val):
        plt.axvline(mode_interval_val, color='pink', linestyle='dotted', linewidth=1.5, label=f'Mode: {mode_interval_val:.2f}s')
    
    plt.title(f'Distribution of HR Sampling Intervals (Up to {GAP_THRESHOLD_SECONDS*2}s)', fontsize=15)
    plt.xlabel('Interval Between Samples (seconds)', fontsize=12)
    plt.ylabel('Frequency of Intervals', fontsize=12)
    plt.legend(fontsize=10)
    plt.grid(axis='y', alpha=0.75, linestyle=':')
    plt.tight_layout()
    plt.savefig("hr_sampling_intervals_plot.png") # Save the plot
    print("Sampling interval plot saved as hr_sampling_intervals_plot.png")
    plt.show()


def main():
    # ... (function remains the same)
    print("--- Loading Data ---")
    hr_df = load_hr_dense_log()
    event_df = load_service_event_log()

    gaps_df, time_diffs = analyze_hr_continuity(hr_df.copy() if not hr_df.empty else hr_df)

    if not event_df.empty:
        print("\n--- Key Service Events (Local Time: Europe/Zurich) ---")
        important_event_types = ['ERROR', 'REMINDER_TRIGGERED', 'MONITORING']
        key_events = event_df[
            event_df['event_type'].isin(important_event_types) | \
            event_df['message'].str.contains("Service Start|Service Stop|Service onCreate|Service onDestroy|foreground|permission", case=False, na=False)
        ]
        if not key_events.empty:
            key_events_local = key_events.tz_convert('Europe/Zurich')
            for timestamp, row in key_events_local.iterrows():
                 print(f"{timestamp.strftime('%Y-%m-%d %H:%M:%S %Z')} | {row['event_type']:<20} | {row['message']}")
        else:
            print("No key service events found matching criteria.")
    
    if not hr_df.empty:
        plot_hr_data(hr_df, event_df, gaps_df)
    else:
        print("Skipping HR data plot as no HR data was loaded.")

    if time_diffs is not None and not time_diffs.empty:
        plot_sampling_intervals(time_diffs)
    else:
        print("Skipping sampling interval plot as no time differences were calculated.")


if __name__ == '__main__':
    main()
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from datetime import datetime, timedelta
import pytz # For timezone conversion
import re # For parsing reminder messages
from collections import deque # For efficient sliding window

# --- Configuration ---
HR_DENSE_LOG_FILE = "mindfulpacer_hr_dense_log.csv"
SERVICE_EVENT_LOG_FILE = "mindfulpacer_hr_service_log.txt"
GAP_THRESHOLD_SECONDS = 15

# --- Reminder Logic Parameters (mirroring the watch service) ---
REMINDER_THRESHOLD_BPM_PY = 90.0
REMINDER_WINDOW_DURATION_PY = timedelta(minutes=5)
MIN_FILL_PERCENTAGE_PY = 0.80 # 80%
MIN_REQUIRED_DURATION_PY = REMINDER_WINDOW_DURATION_PY * MIN_FILL_PERCENTAGE_PY
REMINDER_COOLDOWN_PY = timedelta(minutes=10)


def parse_iso_timestamp(ts_str):
    # ... (function remains the same from your last version) ...
    formats_to_try = [
        '%Y-%m-%dT%H:%M:%S.%fZ',
        '%Y-%m-%dT%H:%M:%SZ',
    ]
    if '.' in ts_str:
        parts = ts_str.split('.')
        if len(parts) == 2:
            frac_seconds = parts[1].replace('Z','')
            if len(frac_seconds) > 6:
                ts_str = parts[0] + '.' + frac_seconds[:6] + 'Z'
            elif len(frac_seconds) < 6:
                 ts_str = parts[0] + '.' + frac_seconds.ljust(6, '0') + 'Z'
    for fmt in formats_to_try:
        try:
            return pd.to_datetime(ts_str, format=fmt, utc=True, errors='raise')
        except ValueError:
            continue
    print(f"Warning: Could not parse timestamp '{ts_str}' with known formats.")
    return pd.NaT

def load_hr_dense_log(filepath=HR_DENSE_LOG_FILE):
    # ... (function remains the same) ...
    try:
        df = pd.read_csv(filepath, header=None, names=['timestamp_str', 'bpm_str'])
        df['timestamp'] = df['timestamp_str'].apply(parse_iso_timestamp)
        df['bpm'] = pd.to_numeric(df['bpm_str'], errors='coerce')
        df.dropna(subset=['timestamp', 'bpm'], inplace=True)
        if df.empty:
            print(f"No valid data after parsing in {filepath}")
            return pd.DataFrame(columns=['bpm']).set_index(pd.to_datetime([], utc=True))
        df.set_index('timestamp', inplace=True)
        if not df.index.is_unique:
            print("Warning: HR DataFrame index contains duplicate timestamps. Aggregating by taking the mean BPM.")
            df = df.groupby(df.index).mean()
        df.sort_index(inplace=True)
        print(f"Successfully loaded and processed {len(df)} HR samples from {filepath}")
        return df
    except FileNotFoundError:
        print(f"Error: Dense HR log file '{filepath}' not found.")
        return pd.DataFrame(columns=['bpm']).set_index(pd.to_datetime([], utc=True))
    except Exception as e:
        print(f"Error loading dense HR log '{filepath}': {e}")
        return pd.DataFrame(columns=['bpm']).set_index(pd.to_datetime([], utc=True))


def load_service_event_log(filepath=SERVICE_EVENT_LOG_FILE):
    # ... (function remains the same) ...
    events = []
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            for i, line in enumerate(f):
                parts = line.strip().split(' | ', 2)
                if len(parts) == 3:
                    ts_str = parts[0].strip()
                    event_type = parts[1].strip()
                    message = parts[2].strip()
                    ts = parse_iso_timestamp(ts_str)
                    if pd.notna(ts):
                        events.append({'timestamp': ts, 'event_type': event_type, 'message': message})
                    else:
                        print(f"Warning: Skipped event line {i+1} due to unparsable timestamp: {line.strip()}")
                elif line.strip(): # Non-empty line that doesn't match format
                    print(f"Warning: Malformed event log line {i+1}: {line.strip()}")

        df = pd.DataFrame(events)
        if not df.empty:
            df.set_index('timestamp', inplace=True)
            if not df.index.is_unique:
                print(f"Warning: Service event DataFrame index is not unique. Keeping first entry for duplicate timestamps.")
                df = df[~df.index.duplicated(keep='first')]
            df.sort_index(inplace=True)
        print(f"Successfully loaded and processed {len(df)} service events from {filepath}")
        return df
    except FileNotFoundError:
        print(f"Error: Service event log file '{filepath}' not found.")
        return pd.DataFrame(columns=['event_type', 'message']).set_index(pd.to_datetime([], utc=True))
    except Exception as e:
        print(f"Error loading service event log '{filepath}': {e}")
        return pd.DataFrame(columns=['event_type', 'message']).set_index(pd.to_datetime([], utc=True))


def analyze_hr_continuity(hr_df):
    # ... (function remains the same) ...
    if hr_df.empty or len(hr_df) < 2:
        print("HR data is empty or insufficient for continuity analysis.")
        return None, pd.Series(dtype='float64')
    hr_df_sorted = hr_df.sort_index()
    hr_df_sorted['time_diff_seconds'] = hr_df_sorted.index.to_series().diff().dt.total_seconds()
    gaps = hr_df_sorted[hr_df_sorted['time_diff_seconds'] > GAP_THRESHOLD_SECONDS]
    print("\n--- HR Monitoring Continuity Analysis ---")
    total_duration_seconds = (hr_df_sorted.index.max() - hr_df_sorted.index.min()).total_seconds() if not hr_df_sorted.empty else 0
    if total_duration_seconds > 0:
        print(f"Total observation span: {timedelta(seconds=int(total_duration_seconds))}")
        actual_time_in_gaps = gaps['time_diff_seconds'].sum()
        monitoring_duration_seconds = total_duration_seconds - actual_time_in_gaps
        monitoring_duration_seconds = max(0, min(monitoring_duration_seconds, total_duration_seconds))
        uptime_percentage = (monitoring_duration_seconds / total_duration_seconds) * 100 if total_duration_seconds > 0 else 0
        print(f"Number of gaps (>{GAP_THRESHOLD_SECONDS}s): {len(gaps)}")
        print(f"Total time duration of identified gaps: {timedelta(seconds=int(actual_time_in_gaps))}")
        print(f"Estimated monitoring uptime (Total Span - Sum of Gap Durations): {timedelta(seconds=int(monitoring_duration_seconds))} ({uptime_percentage:.2f}%)")
        if not gaps.empty:
            print("\nDetected Gaps (gap starts after previous sample, ends at current sample's timestamp):")
            for timestamp, row in gaps.iterrows():
                gap_start_time = timestamp - pd.Timedelta(seconds=row['time_diff_seconds'])
                print(f"  Gap from ~{gap_start_time.tz_convert('Europe/Zurich').strftime('%Y-%m-%d %H:%M:%S %Z')} to {timestamp.tz_convert('Europe/Zurich').strftime('%Y-%m-%d %H:%M:%S %Z')} (Duration: {pd.Timedelta(seconds=row['time_diff_seconds'])})")
    else:
        print("Not enough data or no significant gaps found for detailed continuity analysis.")
    return gaps, hr_df_sorted['time_diff_seconds'].dropna()


def calculate_expected_triggers(hr_df):
    """
    Calculates when reminders should have been triggered based on HR data.
    Returns a list of tuples: (trigger_timestamp_utc, window_start_utc, window_end_utc)
    """
    if hr_df.empty or len(hr_df) < 2:
        return []

    print("\n--- Calculating Expected Reminder Triggers (Python Logic) ---")
    expected_triggers = []
    last_expected_trigger_time_utc = None
    
    # Using a deque for an efficient sliding window
    # Store (timestamp, bpm) tuples
    current_window_samples = deque() 

    for current_ts_utc, row in hr_df.iterrows():
        current_bpm = row['bpm']
        current_window_samples.append({'timestamp': current_ts_utc, 'bpm': current_bpm})

        # Remove samples older than WINDOW_DURATION from the left of the deque
        window_start_boundary = current_ts_utc - REMINDER_WINDOW_DURATION_PY
        while current_window_samples and current_window_samples[0]['timestamp'] < window_start_boundary:
            current_window_samples.popleft()

        if not current_window_samples:
            continue

        # Check actual duration covered by samples in the current window
        first_sample_ts_in_window = current_window_samples[0]['timestamp']
        last_sample_ts_in_window = current_window_samples[-1]['timestamp'] # which is current_ts_utc
        
        actual_duration_covered = last_sample_ts_in_window - first_sample_ts_in_window

        if actual_duration_covered >= MIN_REQUIRED_DURATION_PY:
            all_above_threshold = True
            for sample in current_window_samples:
                if sample['bpm'] <= REMINDER_THRESHOLD_BPM_PY: # Watch logic is > threshold
                    all_above_threshold = False
                    break
            
            if all_above_threshold:
                # Check cooldown for script-calculated triggers
                if last_expected_trigger_time_utc is None or \
                   (current_ts_utc - last_expected_trigger_time_utc >= REMINDER_COOLDOWN_PY):
                    
                    trigger_info = {
                        'trigger_time': current_ts_utc, # Time the condition was met
                        'window_start': window_start_boundary, # The conceptual start of this window
                        'window_end': current_ts_utc, # The conceptual end of this window
                        'num_samples_in_trigger_window': len(current_window_samples),
                        'actual_span_of_trigger_samples': actual_duration_covered
                    }
                    expected_triggers.append(trigger_info)
                    last_expected_trigger_time_utc = current_ts_utc
                    print(f"Expected Trigger Calculated: At {current_ts_utc.tz_convert('Europe/Zurich').strftime('%H:%M:%S')} "
                          f"(Window: {window_start_boundary.tz_convert('Europe/Zurich').strftime('%H:%M:%S')} - {current_ts_utc.tz_convert('Europe/Zurich').strftime('%H:%M:%S')}), "
                          f"Samples: {len(current_window_samples)}, Span: {actual_duration_covered}")
    return expected_triggers


def plot_hr_data(hr_df, event_df, gaps_df, calculated_triggers_info): # Added calculated_triggers_info
    # ... (function signature and initial setup same as before) ...
    if hr_df.empty:
        print("No HR data to plot.")
        return

    swiss_tz = pytz.timezone('Europe/Zurich')
    hr_df_local = hr_df.tz_convert(swiss_tz)
    event_df_local = event_df.tz_convert(swiss_tz) if not event_df.empty else event_df
    gaps_df_local = gaps_df.tz_convert(swiss_tz) if gaps_df is not None and not gaps_df.empty else gaps_df

    fig, ax = plt.subplots(figsize=(18, 9))
    main_hr_line, = ax.plot(hr_df_local.index, hr_df_local['bpm'], label='Heart Rate (BPM)', color='cornflowerblue', linewidth=1.5, marker='.', markersize=3, alpha=0.7)
    
    if gaps_df_local is not None and not gaps_df_local.empty:
        for timestamp, row in gaps_df_local.iterrows():
            gap_start_time = timestamp - pd.Timedelta(seconds=row['time_diff_seconds'])
            ax.axvspan(gap_start_time, timestamp, color='salmon', alpha=0.3, label='_nolegend_')

    # Plot Actual Logged Reminder Windows and Trigger Points
    actual_reminder_events_local = event_df_local[event_df_local['event_type'] == 'REMINDER_TRIGGERED']
    plot_actual_reminder_x_markers = []
    plot_actual_reminder_y_markers = []

    if not actual_reminder_events_local.empty:
        for reminder_idx_local, reminder_row in actual_reminder_events_local.iterrows():
            message = reminder_row['message']
            match = re.search(r"WindowStart=([\dT.:\-Z]+).*Now=([\dT.:\-Z]+)", message)
            if match:
                window_start_str, window_end_str = match.groups()
                window_start_utc = parse_iso_timestamp(window_start_str)
                window_end_utc = parse_iso_timestamp(window_end_str)
                if pd.notna(window_start_utc) and pd.notna(window_end_utc):
                    ax.axvspan(window_start_utc.tz_convert(swiss_tz), window_end_utc.tz_convert(swiss_tz), 
                               color='lightgoldenrodyellow', alpha=0.4, zorder=0, label='_nolegend_')
            
            closest_hr_ts_utc = hr_df.index.asof(reminder_idx_local.tz_convert('UTC'))
            if pd.notna(closest_hr_ts_utc) and abs((reminder_idx_local.tz_convert('UTC') - closest_hr_ts_utc).total_seconds()) < 10:
                bpm_value = hr_df.loc[closest_hr_ts_utc, 'bpm']
                if pd.notna(bpm_value):
                    plot_actual_reminder_x_markers.append(closest_hr_ts_utc.tz_convert(swiss_tz))
                    plot_actual_reminder_y_markers.append(bpm_value)
        
        if plot_actual_reminder_x_markers:
            ax.scatter(plot_actual_reminder_x_markers, plot_actual_reminder_y_markers,
                       color='magenta', marker='X', s=150, edgecolor='black', zorder=5, label='_nolegend_')

    # Plot Calculated Reminder Windows and Trigger Points
    plot_calculated_reminder_x_markers = []
    plot_calculated_reminder_y_markers = []
    if calculated_triggers_info:
        for trigger_info in calculated_triggers_info:
            calc_window_start_local = trigger_info['window_start'].tz_convert(swiss_tz)
            calc_window_end_local = trigger_info['window_end'].tz_convert(swiss_tz) # This is also the trigger time
            ax.axvspan(calc_window_start_local, calc_window_end_local, 
                       color='palegreen', alpha=0.35, zorder=0.1, label='_nolegend_') # Different color, slightly different zorder

            # For scatter marker at the calculated trigger time
            trigger_time_utc = trigger_info['trigger_time']
            if trigger_time_utc in hr_df.index: # Exact match
                 bpm_value_calc = hr_df.loc[trigger_time_utc, 'bpm']
                 if pd.notna(bpm_value_calc):
                    plot_calculated_reminder_x_markers.append(trigger_time_utc.tz_convert(swiss_tz))
                    plot_calculated_reminder_y_markers.append(bpm_value_calc)
            else: # Find closest if no exact match (less likely as trigger_time is from hr_df)
                closest_hr_ts_utc_calc = hr_df.index.asof(trigger_time_utc)
                if pd.notna(closest_hr_ts_utc_calc) and abs((trigger_time_utc - closest_hr_ts_utc_calc).total_seconds()) < 2: # Smaller tolerance
                    bpm_value_calc = hr_df.loc[closest_hr_ts_utc_calc, 'bpm']
                    if pd.notna(bpm_value_calc):
                        plot_calculated_reminder_x_markers.append(closest_hr_ts_utc_calc.tz_convert(swiss_tz))
                        plot_calculated_reminder_y_markers.append(bpm_value_calc)

        if plot_calculated_reminder_x_markers:
            ax.scatter(plot_calculated_reminder_x_markers, plot_calculated_reminder_y_markers,
                       color='blue', marker='P', s=160, edgecolor='black', zorder=6, label='_nolegend_') # P for Plus sign

    # ... (service start/stop event plotting remains the same) ...
    service_start_events_local = event_df_local[event_df_local['message'].str.contains("Starting HR monitoring", case=False, na=False)]
    service_stop_events_local = event_df_local[event_df_local['message'].str.contains("Stopping HR monitoring", case=False, na=False)]
    for t_start in service_start_events_local.index:
        ax.axvline(t_start, color='green', linestyle='--', linewidth=1.5, label='_nolegend_')
    for t_stop in service_stop_events_local.index:
        ax.axvline(t_stop, color='darkorange', linestyle='--', linewidth=1.5, label='_nolegend_')


    legend_handles = [main_hr_line]
    if not service_start_events_local.empty:
        legend_handles.append(plt.Line2D([0], [0], color='green', linestyle='--', lw=1.5, label='Service Start'))
    if not service_stop_events_local.empty:
        legend_handles.append(plt.Line2D([0], [0], color='darkorange', linestyle='--', lw=1.5, label='Service Stop'))
    if gaps_df is not None and not gaps_df.empty:
         legend_handles.append(plt.Rectangle((0,0),1,1, facecolor='salmon', alpha=0.3, label=f'Gap > {GAP_THRESHOLD_SECONDS}s'))
    if plot_actual_reminder_x_markers:
        legend_handles.append(plt.Line2D([0], [0], marker='X', color='w', markerfacecolor='magenta', markeredgecolor='black', markersize=10, label='Logged Reminder Trigger'))
    if not actual_reminder_events_local.empty: # For the shaded actual window
        legend_handles.append(plt.Rectangle((0,0),1,1, facecolor='lightgoldenrodyellow', alpha=0.4, label='Logged Reminder Window'))
    if plot_calculated_reminder_x_markers: # For calculated trigger points
        legend_handles.append(plt.Line2D([0], [0], marker='P', color='w', markerfacecolor='blue', markeredgecolor='black', markersize=10, label='Script-Calculated Trigger'))
    if calculated_triggers_info: # For calculated shaded window
         legend_handles.append(plt.Rectangle((0,0),1,1, facecolor='palegreen', alpha=0.35, label='Script-Calculated Window'))


    ax.set_title('Heart Rate Monitoring Over Time (Local Time: Europe/Zurich)', fontsize=16)
    ax.set_xlabel('Time (HH:MM:SS)', fontsize=12)
    ax.set_ylabel('Heart Rate (BPM)', fontsize=12)
    
    ax.legend(handles=legend_handles, fontsize=9, loc='upper left') # Adjusted fontsize
    ax.grid(True, which='major', linestyle='-.', linewidth=0.5, alpha=0.7)
    ax.grid(True, which='minor', linestyle=':', linewidth=0.3, alpha=0.5)
    
    ax.xaxis.set_major_formatter(mdates.DateFormatter('%H:%M:%S', tz=swiss_tz))
    ax.xaxis.set_minor_locator(mdates.SecondLocator(interval=60 * 5))
    ax.xaxis.set_major_locator(mdates.MinuteLocator(interval=30))
    fig.autofmt_xdate(rotation=30, ha='right')
    
    plt.tight_layout()
    plt.savefig("hr_monitoring_plot_with_calculated.png") # New filename
    print("\nPlot saved as hr_monitoring_plot_with_calculated.png")
    plt.show()

def plot_sampling_intervals(time_diffs_series):
    # ... (function remains the same) ...
    if time_diffs_series.empty or time_diffs_series.isnull().all():
        print("No valid time differences to plot for sampling intervals.")
        return
    plt.figure(figsize=(12, 7))
    valid_intervals = time_diffs_series[time_diffs_series <= GAP_THRESHOLD_SECONDS * 2] 
    if valid_intervals.empty:
        print(f"No sampling intervals less than or equal to {GAP_THRESHOLD_SECONDS*2}s found.")
        return
    n_bins = min(50, len(valid_intervals.unique())) if len(valid_intervals.unique()) > 1 else 10
    plt.hist(valid_intervals, bins=n_bins, color='skyblue', edgecolor='black', alpha=0.7)
    mean_interval = valid_intervals.mean()
    median_interval = valid_intervals.median()
    mode_interval = valid_intervals.mode()
    mode_interval_val = mode_interval[0] if not mode_interval.empty else float('nan')

    plt.axvline(mean_interval, color='red', linestyle='dashed', linewidth=1.5, label=f'Mean: {mean_interval:.2f}s')
    plt.axvline(median_interval, color='green', linestyle='dashed', linewidth=1.5, label=f'Median: {median_interval:.2f}s')
    if pd.notna(mode_interval_val):
        plt.axvline(mode_interval_val, color='purple', linestyle='dotted', linewidth=1.5, label=f'Mode: {mode_interval_val:.2f}s')
    
    plt.title(f'Distribution of HR Sampling Intervals (Up to {GAP_THRESHOLD_SECONDS*2}s)', fontsize=15)
    plt.xlabel('Interval Between Samples (seconds)', fontsize=12)
    plt.ylabel('Frequency of Intervals', fontsize=12)
    plt.legend(fontsize=10)
    plt.grid(axis='y', alpha=0.75, linestyle=':')
    plt.tight_layout()
    plt.savefig("hr_sampling_intervals_plot.png") 
    print("Sampling interval plot saved as hr_sampling_intervals_plot.png")
    plt.show()


def main():
    print("--- Loading Data ---")
    hr_df = load_hr_dense_log()
    event_df = load_service_event_log()

    gaps_df, time_diffs = analyze_hr_continuity(hr_df.copy() if not hr_df.empty else hr_df)
    
    # Calculate expected triggers from the dense HR log
    calculated_triggers = calculate_expected_triggers(hr_df.copy() if not hr_df.empty else hr_df) # Pass a copy
    
    if not event_df.empty:
        print("\n--- Key Service Events (Local Time: Europe/Zurich) ---")
        # ... (existing event printing logic) ...
        important_event_types = ['ERROR', 'REMINDER_TRIGGERED', 'MONITORING']
        key_events = event_df[
            event_df['event_type'].isin(important_event_types) | \
            event_df['message'].str.contains("Service Start|Service Stop|Service onCreate|Service onDestroy|foreground|permission", case=False, na=False)
        ]
        if not key_events.empty:
            key_events_local = key_events.tz_convert('Europe/Zurich')
            for timestamp, row in key_events_local.iterrows():
                 print(f"{timestamp.strftime('%Y-%m-%d %H:%M:%S %Z')} | {row['event_type']:<20} | {row['message']}")
        else:
            print("No key service events found matching criteria.")

    if not hr_df.empty:
        plot_hr_data(hr_df, event_df, gaps_df, calculated_triggers) # Pass calculated triggers
    else:
        print("Skipping HR data plot as no HR data was loaded.")

    if time_diffs is not None and not time_diffs.empty:
        plot_sampling_intervals(time_diffs)
    else:
        print("Skipping sampling interval plot as no time differences were calculated.")

if __name__ == '__main__':
    main()
