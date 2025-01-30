import time
from psycopg2 import OperationalError as pgerror

from django.db.utils import OperationalError
from django.core.management.base import BaseCommand

class Comand(BaseCommand):
    """Tell Django to wait for database connection"""

    def handle(self, *args, **options):
        self.stdout.write("Waiting for database connection ...")
        db_up = False
        while not db_up:
            try:
                self.check(databse=["default"])
                db_up = True
            except (pgerror, OperationalError):
                self.stdout.write("Database unavailable, waiting 1 second...")
                time.sleep(1)

        self.stdout.write(self.style.SUCCESS("Database connected!"))