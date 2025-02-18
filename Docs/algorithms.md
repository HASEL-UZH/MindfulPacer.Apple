# Algorithms

## Check Missed Reflections Algorithm

The purpose of the **Check Missed Reflections** algorithm is to identify moments when a user’s health data indicates that they have exceeded a set threshold over a given period (reminder interval). This algorithm is used to determine when a “reflection” (i.e., an event indicating that the user’s activity or heart rate crossed a predefined threshold) has occurred. These reflections can then trigger feedback, reminders, or further analysis.

### 1. Data Collection

#### Step Data
- The algorithm retrieves all step count samples from the past 24 hours.
- For each step reminder (which has a defined threshold and time interval), the algorithm uses a sliding window approach:
  - It sums the step counts over consecutive samples within the reminder’s interval.
  - If the cumulative sum in any window reaches or exceeds the threshold, a candidate reflection is recorded using the timestamp of the most recent sample in that window.

#### Heart Rate Data
- Similarly, for heart rate reminders, the algorithm fetches heart rate samples from the past 24 hours:
  - It filters out all samples that do not meet or exceed the heart rate threshold.
  - Then, it merges consecutive or overlapping samples (or intervals) where the heart rate is above the threshold.
  - If the duration of any merged interval meets or exceeds the specified interval of the reminder, a candidate reflection is created using the end time of that interval.

### 2. Candidate Reflection Generation

After processing both step and heart rate data:
- A list of raw candidate reflections is generated. Each candidate reflection is associated with:
  - The reminder that triggered it.
  - A timestamp:
    - For steps: the end time of the sliding window.
    - For heart rate: the end time of the merged interval.

### 3. Post-Processing and Filtering

To avoid redundancy and ensure that only the most significant reflections are highlighted, the algorithm applies additional filtering:

#### Partitioning by Measurement Type
- The raw candidate reflections are divided into two groups:
  - **Steps Reflections**
  - **Heart Rate Reflections**

#### Overlapping and Redundancy Filtering
Within each group, reflections are further refined:
- **Strong Reflections:**  
  Reflections associated with a “strong” (red) reminder are always kept.
- **Non-Strong Reflections (e.g., Medium/Light):**
  - The reflections are sorted chronologically.
  - If two reflections occur very close together (i.e., within one-quarter of the reminder’s interval), they are considered overlapping.
  - In cases of overlap, the algorithm calculates a “seriousness score” for each reflection (using the product of the threshold value and the reminder’s time interval).
  - Only the reflection with the higher score is retained, ensuring that minor fluctuations do not lead to multiple alerts.

#### Limiting the Number of Reflections
- For each measurement type, after filtering, the algorithm limits the final results to the most recent five reflections.
- If there are fewer than five reflections available, it returns them as they are. This ensures that the output remains concise and relevant.

#### Actioned Reflection Filtering
- Finally, any reflections that have already been acted upon (i.e., the user has already seen or responded to them) are removed from the final result set.

### 4. Outcome

The final result of the algorithm is a list of missed reflections that:
- Represent significant events where the user exceeded their activity or heart rate thresholds.
- Are grouped and filtered to avoid noise (multiple reflections for what is essentially the same event).
- Are limited to a manageable number per measurement type (up to 5 recent events).

This refined list is then used by the app to provide feedback to the user, trigger notifications, or for further analysis in the context of the user’s health data.