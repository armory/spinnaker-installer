import requests
from requests.packages.urllib3.util.retry import Retry
from requests.adapters import HTTPAdapter
import logging
import sys

# setup logging for our module
requests_logger = logging.getLogger("requests")
ch = logging.StreamHandler(sys.stdout)
ch.setLevel(logging.DEBUG)
requests_logger.addHandler(ch)

def create_session(total_retries, backoff_factor, backoff_max):
    session = requests.Session()
    Retry.BACKOFF_MAX = 1
    retries = Retry(total=total_retries,
                    backoff_factor=backoff_factor,
                    status_forcelist=[301,302,500,502,503,504]
                )
    session.mount('http://', HTTPAdapter(max_retries=retries))
    return session
