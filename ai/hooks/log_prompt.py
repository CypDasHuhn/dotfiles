import json
import os
import sys
import tempfile
from contextlib import contextmanager
from datetime import datetime
from pathlib import Path


@contextmanager
def locked(file):
    if os.name == "nt":
        import msvcrt

        file.seek(0)
        msvcrt.locking(file.fileno(), msvcrt.LK_LOCK, 1)
        try:
            yield
        finally:
            file.seek(0)
            msvcrt.locking(file.fileno(), msvcrt.LK_UNLCK, 1)
    else:
        import fcntl

        fcntl.flock(file.fileno(), fcntl.LOCK_EX)
        try:
            yield
        finally:
            fcntl.flock(file.fileno(), fcntl.LOCK_UN)


def read_history(path):
    if not path.exists():
        return []
    with path.open(encoding="utf-8") as file:
        history = json.load(file)
    if not isinstance(history, list):
        raise ValueError(f"{path} must contain a JSON array")
    return history


def write_history(path, history):
    descriptor, temporary_name = tempfile.mkstemp(
        dir=path.parent,
        prefix=f".{path.name}.",
        suffix=".tmp",
        text=True,
    )
    temporary_path = Path(temporary_name)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as file:
            json.dump(history, file, ensure_ascii=False, indent=2)
            file.write("\n")
        os.chmod(temporary_path, 0o600)
        os.replace(temporary_path, path)
    finally:
        temporary_path.unlink(missing_ok=True)


def main():
    event = json.load(sys.stdin)
    session_id = event["session_id"]
    prompt = event["prompt"]
    history_path = (
        Path(sys.argv[1]).expanduser()
        if len(sys.argv) > 1
        else Path.home() / "dotfiles/ai/generated/prompt-history.json"
    )
    lock_path = history_path.with_name(f".{history_path.name}.lock")
    history_path.parent.mkdir(parents=True, exist_ok=True)

    with lock_path.open("a+b") as lock_file:
        lock_file.seek(0, os.SEEK_END)
        if lock_file.tell() == 0:
            lock_file.write(b"\0")
            lock_file.flush()
            os.chmod(lock_path, 0o600)
        with locked(lock_file):
            history = read_history(history_path)
            message_num = 1 + max(
                (
                    entry.get("message_num", 0)
                    for entry in history
                    if entry.get("session_id") == session_id
                ),
                default=0,
            )
            history.append(
                {
                    "session_id": session_id,
                    "message_num": message_num,
                    "message_datetime": datetime.now().astimezone().isoformat(timespec="seconds"),
                    "message_content": prompt,
                }
            )
            write_history(history_path, history)


if __name__ == "__main__":
    main()
