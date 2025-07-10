from datetime import timedelta
from uuid import uuid4

class Reminder:
    def __init__(self, measurement_type="Steps", reminder_type="Strong", threshold=0, interval="4 Hours"):
        self.id = str(uuid4())
        self.measurement_type = measurement_type
        self.reminder_type = reminder_type
        self.threshold = threshold
        self.interval = interval

    @property
    def trigger_summary(self):
        if self.measurement_type == "Heart Rate":
            return f"Above {self.threshold} bpm for {self.interval.lower()}"
        return f"Above {self.threshold} steps within {self.interval.lower()}"

    @property
    def threshold_units(self):
        if self.measurement_type == "Heart Rate":
            return "bpm"
        return "steps"

class ReminderType:
    LIGHT = "Light"
    MEDIUM = "Medium"
    STRONG = "Strong"

class Interval:
    # Step intervals
    THIRTY_MINUTES = "30 Minutes"
    ONE_HOUR = "1 Hour"
    TWO_HOURS = "2 Hours"
    FOUR_HOURS = "4 Hours"
    ONE_DAY = "1 Day"
    # Heart rate intervals
    IMMEDIATELY = "Immediately"
    FIVE_MINUTES = "5 Minutes"
    TEN_MINUTES = "10 Minutes"
    FIFTEEN_MINUTES = "15 Minutes"
    THIRTY_MINUTES = "30 Minutes"
    ONE_HOUR = "1 Hour"

    @staticmethod
    def time_interval(interval):
        intervals = {
            "30 Minutes": 30 * 60,      # 1800 seconds
            "1 Hour": 60 * 60,          # 3600 seconds
            "2 Hours": 2 * 60 * 60,     # 7200 seconds
            "4 Hours": 4 * 60 * 60,     # 14400 seconds
            "1 Day": 24 * 60 * 60,      # 86400 seconds
            "Immediately": 0,           # 0 seconds
            "5 Minutes": 5 * 60,        # 300 seconds
            "10 Minutes": 10 * 60,      # 600 seconds
            "15 Minutes": 15 * 60,      # 900 seconds
        }
        return intervals.get(interval, 0)

    @staticmethod
    def buffer(interval):
        buffers = {
            "30 Minutes": timedelta(seconds=6),    # 6 seconds
            "1 Hour": timedelta(seconds=12),       # 12 seconds
            "2 Hours": timedelta(seconds=30),      # 30 seconds
            "4 Hours": timedelta(seconds=60),      # 60 seconds
            "1 Day": timedelta(seconds=0),         # 0 seconds
            "Immediately": timedelta(seconds=0),   # 0 seconds
            "5 Minutes": timedelta(seconds=1),     # 1 second
            "10 Minutes": timedelta(seconds=2),    # 2 seconds
            "15 Minutes": timedelta(seconds=3),    # 3 seconds
        }
        return buffers.get(interval, timedelta(seconds=0))

class MissedReflection:
    def __init__(self, reminder, date):
        self.measurement_type = reminder.measurement_type
        self.reminder_type = reminder.reminder_type
        self.threshold = reminder.threshold
        self.interval = reminder.interval
        self.date = date
        self.id = f"{self.measurement_type}-{self.reminder_type}-{self.threshold}-{self.interval}-{self.date.timestamp()}"

    @property
    def trigger_summary(self):
        if self.measurement_type == "Heart Rate":
            return f"Above {self.threshold} bpm for {self.interval.lower()}"
        return f"Above {self.threshold} steps within {self.interval.lower()}"