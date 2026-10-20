import SwiftUI

struct PackageList: View {
    @Environment(Store.self) private var store
    @State private var adding = false
    @State private var path: [Parcel] = []
    let archive: Bool

    private var parcels: [Parcel] { archive ? store.archived : store.active }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if parcels.isEmpty {
                    if archive {
                        ContentUnavailableView("Nothing archived", systemImage: "archivebox",
                            description: Text("Swipe a delivered package to archive it."))
                    } else {
                        ContentUnavailableView("No packages", systemImage: "shippingbox",
                            description: Text("Paste a UPS tracking number or link."))
                    }
                } else {
                    List {
                        ForEach(parcels) { p in
                            NavigationLink(value: p) { Row(parcel: p) }
                                .macCard()
                                .contextMenu {
                                    Button(archive ? "Unarchive" : "Archive") { store.setArchived(p, !archive) }
                                    Button("Delete", role: .destructive) { store.remove(p) }
                                }
                                .swipeActions(edge: .trailing) {
                                    Button("Delete", systemImage: "trash", role: .destructive) { store.remove(p) }
                                    Button(archive ? "Unarchive" : "Archive", systemImage: archive ? "tray.and.arrow.up" : "archivebox") {
                                        store.setArchived(p, !archive)
                                    }
                                    .tint(Brand.accent)
                                }
                        }
                    }
                    .cartonList()
                    .macListGround()
                }
            }
            .navigationTitle(archive ? "Archive" : "Cartons")
            .navigationDestination(for: Parcel.self) { Detail(parcel: $0) }
            .toolbar { if !archive { Button("Add", systemImage: "plus") { adding = true } } }
            .sheet(isPresented: $adding) { AddSheet() }
            .refreshable { await store.refreshAll() }
            .task {
                // QA hook: -open shows the first package
                if !archive, ProcessInfo.processInfo.arguments.contains("-open"), let first = parcels.first { path = [first] }
                if !archive, ProcessInfo.processInfo.arguments.contains("-addsheet") { adding = true }  // QA hook
                await store.refreshAll()
            }
        }
    }
}

struct Row: View {
    @Environment(Store.self) private var store
    let parcel: Parcel

    private var status: Status? { store.statuses[parcel.number] }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(parcel.name.isEmpty ? parcel.number : parcel.name).font(.carton(.headline, "Semibold")).lineLimit(1)
                Text(subtitle).font(.carton(.subheadline)).foregroundStyle(.secondary).lineLimit(2)
            }
            Spacer(minLength: 0)
            countdown
        }
        .padding(.vertical, 8)
    }

    private var subtitle: String {
        if let s = status { return s.status }
        return store.errors[parcel.number] ?? "Checking"
    }

    @ViewBuilder private var countdown: some View {
        if let s = status, s.delivered {
            Image(systemName: "checkmark.circle.fill").font(.title).foregroundStyle(Brand.accent)
        } else if let d = status?.daysLeft {
            VStack(spacing: 0) {
                Text(d <= 0 ? "Today" : "\(d)").font(.carton(.title, "Semibold", size: d <= 0 ? 17 : 32))
                if d > 0 { Text(d == 1 ? "day" : "days").font(.carton(.caption, "Medium")).foregroundStyle(.secondary) }
            }
            .foregroundStyle(Brand.accent)
            .frame(minWidth: 48)
        }
    }
}

struct Detail: View {
    @Environment(Store.self) private var store
    let parcel: Parcel
    @State private var renaming = false
    @State private var newName = ""

    private var status: Status? { store.statuses[parcel.number] }
    private var current: Parcel { store.parcels.first { $0.number == parcel.number } ?? parcel }

    var body: some View {
        List {
            if let s = status, let d = s.daysLeft, !s.delivered {
                Section {
                    VStack(spacing: 4) {
                        Text(d <= 0 ? "Today" : "\(d)").font(.carton(.largeTitle, "Bold", size: d <= 0 ? 34 : 64)).foregroundStyle(Brand.accent)
                        Text(d <= 0 ? "arriving" : d == 1 ? "day to go" : "days to go").font(.carton(.subheadline, "Medium")).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                }
            }
            if let steps = status?.steps, !steps.isEmpty {
                Section("Progress") {
                    ForEach(Array(steps.enumerated()), id: \.offset) { i, step in
                        HStack(spacing: 16) {
                            Image(systemName: step.state == "completed" ? "checkmark.circle.fill" : step.state == "active" ? "shippingbox.circle.fill" : "circle")
                                .font(.title3).foregroundStyle(step.state == "inactive" ? Color.secondary : Brand.accent)
                            Text(step.name).font(.carton(.body, step.state == "active" ? "Semibold" : "Regular"))
                                .foregroundStyle(step.state == "inactive" ? .secondary : .primary)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(step.name), \(step.state == "completed" ? "done" : step.state == "active" ? "current step" : "not yet")")
                    }
                }
            }
            Section {
                LabeledContent("UPS", value: parcel.number)
                if let s = status {
                    LabeledContent("Status", value: s.status)
                    if let eta = s.eta { LabeledContent(s.delivered ? "Delivered" : "Expected", value: eta) }
                    if let l = s.lastLocation { LabeledContent("Last scan", value: l) }
                    if let v = s.service { LabeledContent("Service", value: v) }
                    if let t = s.shipTo { LabeledContent("Ship to", value: t) }
                } else if let e = store.errors[parcel.number] {
                    Text(e).foregroundStyle(.secondary)
                }
                Link("Open on ups.com", destination: URL(string: "https://www.ups.com/track?tracknum=\(parcel.number)")!)
            }
        }
        .cartonList()
        .navigationTitle(current.name.isEmpty ? "Package" : current.name)
        .inlineTitle()
        .toolbar { Button("Rename", systemImage: "pencil") { newName = current.name; renaming = true } }
        .alert("Name this package", isPresented: $renaming) {
            TextField("Book, shoes, anything", text: $newName)
            Button("Save") { store.rename(parcel, newName) }
            Button("Cancel", role: .cancel) {}
        }
        .refreshable { await store.refresh(parcel.number) }
    }
}

struct AddSheet: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var name = ""
    @State private var bad = false

    var body: some View {
        NavigationStack {
            Form {
                TextField("Tracking number or link", text: $text)
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.characters)
                    #endif
                TextField("Name (optional)", text: $name)
                if bad { Text("That doesn't look like a UPS tracking number.").foregroundStyle(.red) }
            }
            .navigationTitle("Add package")
            .inlineTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { if store.add(text, name: name) { dismiss() } else { bad = true } }
                }
            }
            .onAppear {  // clipboard detect
                if let c = Clipboard.string, Store.parse(c) != nil { text = c }
            }
        }
        .presentationDetents([.medium])
    }
}
