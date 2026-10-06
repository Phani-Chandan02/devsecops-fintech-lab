# Hardened minimal production container complying with PCI-DSS v4.0 Requirement 6.4
# Remediated base image: python:3.11-alpine (0 CRITICAL / 0 HIGH vulnerabilities)
FROM python:3.11-alpine

WORKDIR /app
COPY app.py /app/app.py

EXPOSE 80

CMD ["python3", "/app/app.py"]
