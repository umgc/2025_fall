import json
import os
import subprocess
import sys
import zipfile
from pathlib import Path


def run_student_programs(language: str, base_dir="."):
    language = language.strip().lower()
    results = []
    inputs = [None]
    
    input_file = Path("input")
    input_lines = input_file.read_text().splitlines()
    if input_file.exists() and len(input_lines) > 0:
        inputs = input_lines

    for dir_entry in Path(base_dir).iterdir():
        if not dir_entry.is_dir():
            continue

        os.chdir(dir_entry)
        print(f"Processing {dir_entry.name}...")

        # Unzip any zip file found
        zip_files = list(Path(".").glob("*.zip"))
        if zip_files:
            with zipfile.ZipFile(zip_files[0], "r") as z:
                z.extractall(".")

        # Read IDs if present
        student_id = Path("studentId").read_text().strip() if Path("studentId").exists() else "unknown"
        assignment_id = Path("assignmentId").read_text().strip() if Path("assignmentId").exists() else "unknown"

        compile_error = None
        exe = None

        # -------------------- Compilation --------------------
        if language == "c":
            exe = "./main.out"
            compile_cmd = ["g++", *map(str, Path(".").glob("*.c")), "-o", exe]
            proc = subprocess.run(compile_cmd, capture_output=True, text=True)
            if proc.returncode != 0:
                compile_error = proc.stderr.strip()

        elif language == "c++":
            exe = "./main.out"
            compile_cmd = ["g++", *map(str, Path(".").glob("*.cpp")), "-o", exe]
            proc = subprocess.run(compile_cmd, capture_output=True, text=True)
            if proc.returncode != 0:
                compile_error = proc.stderr.strip()

        elif language == "java":
            proc = subprocess.run(["javac", "main.java"], capture_output=True, text=True)
            if proc.returncode != 0:
                compile_error = proc.stderr.strip()

        elif language == "python":
            pass  # no compilation

        else:
            print(f"Unsupported language: {language}")
            os.chdir("..")
            continue

        if compile_error:
            results.append({
                "output": [compile_error],
                "studentId": student_id,
                "assignmentId": assignment_id,
                "error": True
            })
            os.chdir("..")
            continue

        # -------------------- Execution --------------------
        for line in inputs:
            if language in ("c", "c++"):
                cmd = [exe] if line is None else [exe, line]
            elif language == "java":
                cmd = ["java", "main"] if line is None else ["java", "main", line]
            elif language == "python":
                cmd = ["python3", "main.py"] if line is None else ["python3", "main.py", line]
            else:
                cmd = []

            proc = subprocess.run(cmd, capture_output=True, text=True)
            output_text = proc.stdout.strip() or proc.stderr.strip()

            results.append({
                "output": [output_text],
                "studentId": student_id,
                "assignmentId": assignment_id,
                "error": proc.returncode != 0
            })

        # -------------------- Cleanup --------------------
        if exe and Path(exe).exists():
            Path(exe).unlink(missing_ok=True)
        for cls in Path(".").glob("*.class"):
            cls.unlink(missing_ok=True)

        os.chdir("..")

    return results


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 evaluate.py <language>")
        print("Language must be one of: C, C++, Java, Python")
        sys.exit(1)

    language = sys.argv[1]
    results = run_student_programs(language)
    payload = {
        'evaluation': results,
        'courseId': os.getenv('COURSE_ID'),
        'assignmentId': os.getenv('ASSIGNMENT_ID')
    }
    print(json.dumps(payload, ensure_ascii=False))
    with open('./payload.json', 'w') as f:
        f.write(json.dumps(payload, ensure_ascii=False))
