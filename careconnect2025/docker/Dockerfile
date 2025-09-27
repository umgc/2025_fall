FROM public.ecr.aws/lambda/python:3.10

# Use the archived EPEL7 repo (RHEL7/EPEL7 are EOL; 'latest-7' 404s)
# Switched to single quotes to prevent shell expansion of $basearch
RUN set -eux; \
    printf '[epel]\nname=EPEL7 archive\nbaseurl=https://archives.fedoraproject.org/pub/archive/epel/7/$basearch/\nenabled=1\ngpgcheck=1\ngpgkey=https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7\n' \
    > /etc/yum.repos.d/epel-archive.repo; \
    yum clean all && yum makecache && \
    yum install -y tesseract tesseract-langpack-eng poppler-utils && \
    yum clean all && rm -rf /var/cache/yum

# Python deps – use headless OpenCV in containers
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# App code
COPY app.py ${LAMBDA_TASK_ROOT}

CMD ["app.lambda_handler"]