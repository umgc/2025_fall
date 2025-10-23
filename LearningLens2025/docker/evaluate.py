import json
import os
import subprocess
import sys
import zipfile
from pathlib import Path


def run_student_programs(language: str, base_dir="."):
    language = language.strip().lower()
    results = []
    timeout_seconds = int(os.getenv('TIMEOUT_SECONDS'))
    # Expected output file should always exist
    expected_outputs: list[dict] = json.loads(Path("expectedOutput").read_text())

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
            exe = "./entry.out"
            compile_cmd = ["g++", *map(str, Path(".").glob("*.c")), "-o", exe]
            proc = subprocess.run(compile_cmd, capture_output=True, text=True)
            if proc.returncode != 0:
                compile_error = proc.stderr.strip()

        elif language == "c++":
            exe = "./entry.out"
            compile_cmd = ["g++", *map(str, Path(".").glob("*.cpp")), "-o", exe]
            proc = subprocess.run(compile_cmd, capture_output=True, text=True)
            if proc.returncode != 0:
                compile_error = proc.stderr.strip()

        elif language == "java":
            proc = subprocess.run(["javac", "entry.java"], capture_output=True, text=True)
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
                "outputs": [{ 'output': compile_error, "error": True, "timedout": False }],
                "studentId": student_id,
                "assignmentId": assignment_id,
            })
            os.chdir("..")
            continue

        result = {
            "outputs": [],
            "studentId": student_id,
            "assignmentId": assignment_id
        }
        # -------------------- Execution --------------------
        for item in expected_outputs:
            # input is optional
            line: str = item.get('input')
            expected_output: str = item['expectedOutput']

            if language in ("c", "c++"):
                cmd = [exe] if line is None else [exe, line]
            elif language == "java":
                cmd = ["java", "entry"] if line is None else ["java", "entry", line]
            elif language == "python":
                cmd = ["python3", "entry.py"] if line is None else ["python3", "entry.py", line]
            else:
                cmd = []

            try:
                proc = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout_seconds)
                output_text = proc.stdout.strip() or proc.stderr.strip()
                error_flag = proc.returncode != 0
                timedout = False
            except subprocess.TimeoutExpired:
                output_text = f"Execution timed out after {timeout_seconds} seconds."
                error_flag = True
                timedout = True

            result['outputs'].append({
                "input": line if line is not None else '',
                'expectedOutput': expected_output,
                "output": output_text,
                "studentId": student_id,
                "assignmentId": assignment_id,
                "error": error_flag,
                "timedout": timedout
            })

        results.append(result)

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
