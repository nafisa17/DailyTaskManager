//
//  ContentView.swift
//  Daily_task_manager
//
//  Created by Nafisa Anjum on 02.03.25.
import SwiftUI
import UserNotifications

// Task Model
struct Task: Identifiable, Hashable, Codable {
    let id = UUID()
    var name: String
    var dueDate: Date?
    var isCompleted: Bool = false
}

struct ContentView: View {
    @State private var tasks: [Task] = []
    @State private var newTask: String = ""
    @State private var isEditing: Bool = false
    @State private var selectedDate = Date()

    var completedTaskCount: Int {
        tasks.filter { $0.isCompleted }.count
    }

    var body: some View {
        VStack {
            // Task Input Section
            HStack {
                TextField("Enter new task", text: $newTask)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                DatePicker("", selection: $selectedDate, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .padding()

                Button(action: addTask) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(.green)
                }
                .padding(.trailing)
                .help("Add Task with Reminder")
            }

            // Task Completion Progress Bar
            if !tasks.isEmpty {
                ProgressView("Completed \(completedTaskCount)/\(tasks.count)", value: Double(completedTaskCount), total: Double(tasks.count))
                    .padding(.horizontal)
            }

            // Task List Section
            if tasks.isEmpty {
                VStack {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No Tasks Yet!")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding(.top, 5)
                }
                .padding()
            } else {
                List {
                    ForEach(tasks) { task in
                        HStack {
                            Button(action: { toggleTaskCompletion(task) }) {
                                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(task.isCompleted ? .green : .blue)
                            }

                            Text(task.name)
                                .strikethrough(task.isCompleted, color: .gray)
                                .foregroundColor(task.isCompleted ? .gray : .primary)

                            Spacer()

                            if let dueDate = task.dueDate {
                                Text(dateFormatter.string(from: dueDate))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            if isEditing {
                                Button(action: { deleteTask(task) }) {
                                    Image(systemName: "trash.fill")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(BorderlessButtonStyle()) // Needed for macOS List buttons
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .frame(minWidth: 500, minHeight: 300)
        .toolbar {
            ToolbarItem {
                Button(action: toggleEditMode) {
                    Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                }
                .help(isEditing ? "Done Editing" : "Edit Tasks")
            }
        }
        .onAppear(perform: loadTasks)
        .onDisappear(perform: saveTasks)
        .onAppear(perform: requestNotificationPermission)
    }

    // Function to add a task with reminder
    func addTask() {
        if !newTask.isEmpty {
            let task = Task(name: newTask, dueDate: selectedDate)
            tasks.append(task)
            scheduleNotification(for: task)
            newTask = ""
            saveTasks()
        }
    }

    // Function to delete a task
    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }

    // Function to toggle task completion
    func toggleTaskCompletion(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            saveTasks()
        }
    }

    // Function to toggle Edit Mode
    func toggleEditMode() {
        isEditing.toggle()
    }

    // Request Notification Permission
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error)")
            }
        }
    }

    // Schedule Notification
    func scheduleNotification(for task: Task) {
        guard let dueDate = task.dueDate else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Reminder"
        content.body = "Task: \(task.name)"
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents([.hour, .minute], from: dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }

    // Save Tasks to UserDefaults
    func saveTasks() {
        if let encodedData = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encodedData, forKey: "tasks")
        }
    }

    // Load Tasks from UserDefaults
    func loadTasks() {
        if let savedData = UserDefaults.standard.data(forKey: "tasks"),
           let decodedTasks = try? JSONDecoder().decode([Task].self, from: savedData) {
            tasks = decodedTasks
        }
    }
}

// Date Formatter
let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
