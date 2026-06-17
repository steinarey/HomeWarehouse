"""Microsoft Graph REST wrapper scoped to the To Do API surface we need.

Only covers what the connector actually uses: list task lists, create a task
(with an open extension carrying the PantryKeeper category id), list tasks in
a list with their extensions, mark a task complete, delete a task.
"""
from __future__ import annotations

from typing import Any, Optional

import httpx

from app.integrations.microsoft_todo.tokens import GRAPH_BASE

EXTENSION_NAME = "com.pantrykeeper.category"


class MicrosoftGraphError(RuntimeError):
    def __init__(self, status_code: int, payload: Any):
        super().__init__(f"Microsoft Graph error {status_code}: {payload}")
        self.status_code = status_code
        self.payload = payload


def _headers(access_token: str) -> dict[str, str]:
    return {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json",
        "Accept": "application/json",
    }


def _raise_for_status(response: httpx.Response) -> None:
    if response.status_code >= 400:
        try:
            payload = response.json()
        except Exception:
            payload = response.text
        raise MicrosoftGraphError(response.status_code, payload)


def list_todo_lists(access_token: str) -> list[dict[str, Any]]:
    with httpx.Client(timeout=15.0) as client:
        response = client.get(f"{GRAPH_BASE}/me/todo/lists", headers=_headers(access_token))
    _raise_for_status(response)
    return response.json().get("value", [])


def create_task(
    access_token: str,
    *,
    list_id: str,
    title: str,
    body: Optional[str] = None,
    category_id: Optional[int] = None,
    warehouse_id: Optional[int] = None,
) -> dict[str, Any]:
    payload: dict[str, Any] = {
        "title": title,
        "importance": "high" if (category_id is None) else "normal",
    }
    if body:
        payload["body"] = {"content": body, "contentType": "text"}

    with httpx.Client(timeout=15.0) as client:
        response = client.post(
            f"{GRAPH_BASE}/me/todo/lists/{list_id}/tasks",
            headers=_headers(access_token),
            json=payload,
        )
    _raise_for_status(response)
    task = response.json()

    # Attach an open extension with the PantryKeeper category id so the poll
    # step can map a completed task back to a category without name parsing.
    if category_id is not None:
        ext_payload = {
            "@odata.type": "microsoft.graph.openTypeExtension",
            "extensionName": EXTENSION_NAME,
            "categoryId": category_id,
            "warehouseId": warehouse_id,
        }
        with httpx.Client(timeout=15.0) as client:
            ext_response = client.post(
                f"{GRAPH_BASE}/me/todo/lists/{list_id}/tasks/{task['id']}/extensions",
                headers=_headers(access_token),
                json=ext_payload,
            )
        _raise_for_status(ext_response)

    return task


def list_tasks_with_extension(access_token: str, *, list_id: str) -> list[dict[str, Any]]:
    """Return every task in the list with its `extensions` expanded so callers
    can read the PantryKeeper open extension client-side.

    Graph paginates with `@odata.nextLink`; we follow it until exhausted.
    """
    results: list[dict[str, Any]] = []
    url: Optional[str] = (
        f"{GRAPH_BASE}/me/todo/lists/{list_id}/tasks?$expand=extensions&$top=100"
    )
    with httpx.Client(timeout=30.0) as client:
        while url:
            response = client.get(url, headers=_headers(access_token))
            _raise_for_status(response)
            data = response.json()
            results.extend(data.get("value", []))
            url = data.get("@odata.nextLink")
    return results


def get_task(access_token: str, *, list_id: str, task_id: str) -> Optional[dict[str, Any]]:
    with httpx.Client(timeout=15.0) as client:
        response = client.get(
            f"{GRAPH_BASE}/me/todo/lists/{list_id}/tasks/{task_id}?$expand=extensions",
            headers=_headers(access_token),
        )
    if response.status_code == 404:
        return None
    _raise_for_status(response)
    return response.json()


def delete_task(access_token: str, *, list_id: str, task_id: str) -> None:
    with httpx.Client(timeout=15.0) as client:
        response = client.delete(
            f"{GRAPH_BASE}/me/todo/lists/{list_id}/tasks/{task_id}",
            headers=_headers(access_token),
        )
    if response.status_code == 404:
        return
    _raise_for_status(response)


def extract_category_id(task: dict[str, Any]) -> Optional[int]:
    """Read the PantryKeeper open extension off a task payload."""
    for ext in task.get("extensions", []) or []:
        if ext.get("extensionName") == EXTENSION_NAME or ext.get("id", "").endswith(EXTENSION_NAME):
            value = ext.get("categoryId")
            if isinstance(value, int):
                return value
            if isinstance(value, str) and value.isdigit():
                return int(value)
    return None
