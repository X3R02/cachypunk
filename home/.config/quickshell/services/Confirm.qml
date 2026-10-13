// A pending confirmation for the confirm dialog (confirm/ConfirmDialog.qml).
// ask() shows the question; accept() runs the command, cancel() drops it.
// Destructive actions go through here instead of acting on one click.
pragma Singleton

import Quickshell
import QtQuick

Singleton {
	id: root

	property bool open: false
	property string question: ""
	property string action: ""
	property var command: []

	function ask(question: string, action: string, command: var): void {
		root.question = question;
		root.action = action;
		root.command = command;
		open = true;
	}

	function accept(): void {
		open = false;
		Quickshell.execDetached(command);
	}

	function cancel(): void {
		open = false;
	}
}
