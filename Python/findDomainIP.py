
def find_domain_ip(log):
    import re
    domains=re.findall(r"\b\w+\.[A-za-z]{1,3}\b",log)
    IpAddress=re.findall(r"(?:\d{1,3}\.){3}\d{1,3}",log)
    print(f"Domains found: {domains}\n")
    print(f"IPs found: {IpAddress}\n")


