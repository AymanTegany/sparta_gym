import os

def fix_file(filepath):
    print(f"Checking {filepath}...")
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    
    # Check if literal '\r\n' is in the text
    if '\\r\\n' in content:
        print(f"Fixing {filepath}...")
        # Replace literal '\r\n' with actual newline
        # Also let's be careful: sometimes it's double escaped, or it has literal '\n'
        fixed_content = content.replace('\\r\\n', '\n').replace('\\n', '\n')
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(fixed_content)

def scan_and_fix(directory):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                fix_file(os.path.join(root, file))

if __name__ == '__main__':
    scan_and_fix('.')
