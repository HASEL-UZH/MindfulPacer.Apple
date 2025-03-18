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
        return f"Above {self.threshold} steps within {self.interval.lower()}"

    @property
    def threshold_units(self):
        return "steps"

class ReminderType:
    LIGHT = "Light"
    MEDIUM = "Medium"
    STRONG = "Strong"

class Interval:
    THIRTY_MINUTES = "30 Minutes"
    ONE_HOUR = "1 Hour"
    TWO_HOURS = "2 Hours"
    FOUR_HOURS = "4 Hours"
    ONE_DAY = "1 Day"

    @staticmethod
    def time_interval(interval):
        intervals = {
            "30 Minutes": 30 * 60,
            "1 Hour": 60 * 60,
            "2 Hours": 2 * 60 * 60,
            "4 Hours": 4 * 60 * 60,
            "1 Day": 24 * 60 * 60
        }
        return intervals.get(interval, 0)

    @staticmethod
    def buffer(interval):
        buffers = {
            "30 Minutes": timedelta(minutes=5),
            "1 Hour": timedelta(minutes=10),
            "2 Hours": timedelta(minutes=10),
            "4 Hours": timedelta(minutes=30),
            "1 Day": timedelta(hours=1)
        }
        return buffers.get(interval, timedelta(hours=1))

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
        return f"Above {self.threshold} steps within {self.interval.lower()}"