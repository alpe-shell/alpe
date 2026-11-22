pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services

Singleton {
    id: root
    readonly property var log: Log.scoped("CalendarService")

    readonly property string backendPref: SettingsData.calendarBackend
    readonly property string activeBackend: {
        switch (backendPref) {
        case "khal":
            return "khal";
        case "dankcal":
            return "dankcal";
        default:
            if (duxBackend.connected)
                return "dankcal";
            if (khalBackend.installed)
                return "khal";
            return "none";
        }
    }

    readonly property bool calendarAvailable: activeBackend !== "none"
    readonly property bool isDuxActive: activeBackend === "dankcal"
    readonly property bool canCreateEvents: isDuxActive && duxBackend.connected
    property bool khalAvailable: true // compatibility alias - calendar card UI gate

    readonly property bool duxConnected: duxBackend.connected
    readonly property bool duxBinaryExists: duxBackend.binaryExists
    readonly property bool duxNeedsLaunch: backendPref === "dankcal" && !duxBackend.connected && !duxBackend.socketFound

    property var calendars: duxBackend.calendars
    property var eventsByDate: ({})
    property var taskEventsByDate: ({})
    property var localTasks: ({})
    property bool isLoading: khalBackend.isLoading
    property string lastError: ""

    property bool _rangeSet: false
    property date lastStartDate
    property date lastEndDate

    onTaskEventsByDateChanged: mergeEvents()
    onActiveBackendChanged: {
        mergeEvents();
        if (_rangeSet)
            loadEvents(lastStartDate, lastEndDate);
    }

    CalendarKhalBackend {
        id: khalBackend
        enabled: root.backendPref !== "dankcal"
        onEventsByDateChanged: root.mergeEvents()
    }

    CalendarDuxBackend {
        id: duxBackend
        enabled: root.backendPref === "dankcal" || root.backendPref === "auto"
        preferred: root.backendPref === "dankcal"
        onEventsByDateChanged: root.mergeEvents()
        onTasksByDateChanged: root.mergeEvents()
        onConnectedChanged: {
            if (connected && root._rangeSet)
                root.loadEvents(root.lastStartDate, root.lastEndDate);
        }
    }

    function loadEvents(startDate, endDate) {
        root.lastStartDate = startDate;
        root.lastEndDate = endDate;
        root._rangeSet = true;
        switch (activeBackend) {
        case "dankcal":
            duxBackend.loadEvents(startDate, endDate);
            break;
        case "khal":
            khalBackend.loadEvents(startDate, endDate);
            break;
        }
    }

    function _activeBackendEventsByDate() {
        switch (activeBackend) {
        case "dankcal":
            return duxBackend.eventsByDate;
        case "khal":
            return khalBackend.eventsByDate;
        default:
            return {};
        }
    }

    function getEventsForDate(date) {
        let dateKey = Qt.formatDate(date, "yyyy-MM-dd");
        return root.eventsByDate[dateKey] || [];
    }

    function hasEventsForDate(date) {
        return getEventsForDate(date).length > 0;
    }

    function writableCalendars() {
        return isDuxActive ? duxBackend.writableCalendars() : [];
    }

    function defaultCalendar() {
        return isDuxActive ? duxBackend.defaultCalendar() : null;
    }

    function launchDuxCalendar() {
        duxBackend.launch();
    }

    function createEvent(fields, callback) {
        if (isDuxActive) {
            duxBackend.createEvent(fields, callback);
            return;
        }
        if (callback)
            callback({
                "error": "read-only backend"
            });
    }

    function updateEvent(id, fields, callback) {
        if (isDuxActive) {
            duxBackend.updateEvent(id, fields, callback);
            return;
        }
        if (callback)
            callback({
                "error": "read-only backend"
            });
    }

    function deleteEvent(id, callback) {
        if (isDuxActive) {
            duxBackend.deleteEvent(id, callback);
            return;
        }
        if (callback)
            callback({
                "error": "read-only backend"
            });
    }

    function loadTasks(text) {
        if (!text || text.trim() === "") {
            root.localTasks = {};
            root.taskEventsByDate = {};
            return;
        }
        try {
            root.localTasks = JSON.parse(text);
            updateTaskEvents();
        } catch (error) {
            log.warn("Failed to parse local tasks JSON: " + error.toString());
        }
    }

    function saveTasks() {
        let dir = Quickshell.env("HOME") + "/.config/niri-calendar-todo";
        Quickshell.execDetached(["mkdir", "-p", dir]);
        tasksFileView.setText(JSON.stringify(root.localTasks, null, 2));
    }

    function updateTaskEvents() {
        let newTaskEvents = {};
        for (let dateKey in root.localTasks) {
            let taskList = root.localTasks[dateKey] || [];
            newTaskEvents[dateKey] = [];
            for (let task of taskList) {
                let eventId = "task_" + task.id;
                let parts = dateKey.split("-");
                let taskDate = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]));

                newTaskEvents[dateKey].push({
                    "id": eventId,
                    "title": task.text,
                    "completed": !!task.completed,
                    "start": taskDate,
                    "end": taskDate,
                    "location": "",
                    "description": "Task from your Planner",
                    "url": "",
                    "calendar": "Todo Planner",
                    "color": "#10B981",
                    "allDay": true,
                    "isMultiDay": false
                });
            }
        }
        root.taskEventsByDate = newTaskEvents;
    }

    function addTaskForDate(date, text) {
        const taskCal = isDuxActive && duxBackend.connected ? duxBackend.defaultTaskCalendar() : null;
        if (taskCal) {
            const due = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
            duxBackend.createTask({
                "calendarId": taskCal.id,
                "summary": text,
                "allDay": true,
                "due": due.toISOString()
            });
            return;
        }
        let dateKey = Qt.formatDate(date, "yyyy-MM-dd");
        let tasks = Object.assign({}, root.localTasks);
        if (!tasks[dateKey])
            tasks[dateKey] = [];
        let taskId = (new Date().getTime()) + "-alpe";
        tasks[dateKey].push({
            "id": taskId,
            "text": text,
            "completed": false
        });
        root.localTasks = tasks;
        updateTaskEvents();
        saveTasks();
    }

    function toggleTask(taskId) {
        if (taskId.startsWith("vtodo_")) {
            const id = taskId.slice(6);
            const task = duxBackend.taskById(id);
            if (task)
                duxBackend.completeTask(id, !task.completed);
            return;
        }
        let cleanId = taskId.replace("task_", "");
        let tasks = Object.assign({}, root.localTasks);
        let updated = false;
        for (let dateKey in tasks) {
            let list = tasks[dateKey];
            for (let item of list) {
                if (item.id === cleanId) {
                    item.completed = !item.completed;
                    updated = true;
                    break;
                }
            }
            if (updated)
                break;
        }
        if (updated) {
            root.localTasks = tasks;
            updateTaskEvents();
            saveTasks();
        }
    }

    function removeTask(taskId) {
        if (taskId.startsWith("vtodo_")) {
            duxBackend.deleteTask(taskId.slice(6));
            return;
        }
        let cleanId = taskId.replace("task_", "");
        let tasks = Object.assign({}, root.localTasks);
        let updated = false;
        for (let dateKey in tasks) {
            let list = tasks[dateKey];
            let filtered = list.filter(item => item.id !== cleanId);
            if (filtered.length !== list.length) {
                if (filtered.length === 0)
                    delete tasks[dateKey];
                else
                    tasks[dateKey] = filtered;
                updated = true;
                break;
            }
        }
        if (updated) {
            root.localTasks = tasks;
            updateTaskEvents();
            saveTasks();
        }
    }

    function reorderTasksForDate(date, orderedIds) {
        let dateKey = Qt.formatDate(date, "yyyy-MM-dd");
        let tasks = Object.assign({}, root.localTasks);
        let v = tasks[dateKey] || [];
        let idToItem = {};
        for (let item of v)
            idToItem[item.id] = item;
        let newV = [];
        for (let tid of orderedIds) {
            if (idToItem[tid])
                newV.push(idToItem[tid]);
        }
        let orderedSet = new Set(orderedIds);
        for (let item of v) {
            if (!orderedSet.has(item.id))
                newV.push(item);
        }
        tasks[dateKey] = newV;
        root.localTasks = tasks;
        updateTaskEvents();
        saveTasks();
    }

    function editTask(taskId, newText) {
        if (taskId.startsWith("vtodo_")) {
            duxBackend.updateTask(taskId.slice(6), {
                "summary": newText
            });
            return;
        }
        let cleanId = taskId.replace("task_", "");
        let tasks = Object.assign({}, root.localTasks);
        let updated = false;
        for (let dateKey in tasks) {
            let list = tasks[dateKey];
            for (let item of list) {
                if (item.id === cleanId) {
                    item.text = newText;
                    updated = true;
                    break;
                }
            }
            if (updated)
                break;
        }
        if (updated) {
            root.localTasks = tasks;
            updateTaskEvents();
            saveTasks();
        }
    }

    function _mergeInto(merged, byDate) {
        for (let dateKey in byDate) {
            if (!merged[dateKey])
                merged[dateKey] = [];
            for (let event of byDate[dateKey]) {
                if (!merged[dateKey].some(e => e.id === event.id))
                    merged[dateKey].push(event);
            }
        }
    }

    function mergeEvents() {
        let merged = {};
        let backendEvents = _activeBackendEventsByDate();

        for (let dateKey in backendEvents)
            merged[dateKey] = [].concat(backendEvents[dateKey]);

        _mergeInto(merged, root.taskEventsByDate);
        if (isDuxActive)
            _mergeInto(merged, duxBackend.tasksByDate);

        for (let dateKey in merged) {
            let list = merged[dateKey];
            for (let idx = 0; idx < list.length; idx++)
                list[idx]._origIdx = idx;
            list.sort((a, b) => {
                let diff = a.start.getTime() - b.start.getTime();
                if (diff !== 0)
                    return diff;
                return a._origIdx - b._origIdx;
            });
        }

        root.eventsByDate = merged;
    }

    FileView {
        id: tasksFileView
        path: Quickshell.env("HOME") + "/.config/niri-calendar-todo/tasks.json"
        blockLoading: false
        blockWrites: false
        atomicWrites: true
        watchChanges: true
        printErrors: false

        onLoaded: loadTasks(tasksFileView.text())

        onLoadFailed: {
            root.localTasks = {};
            root.taskEventsByDate = {};
        }
    }
}
