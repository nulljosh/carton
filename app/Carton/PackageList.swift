import SwiftUI

struct PackageList: View {
    @Environment(Store.self) private var store
    @State private var adding = false
    let archive: Bool

    private var parcels: [Parcel] { archive ? store.archived : store.active }

    var body: some View {
        NavigationStack {
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
                                .swipeActions(edge: .trailing) {
                                    Button("Delete", systemImage: "trash", role: .destructive) { store.remove(p) }
                                    Button(archive ? "Unarchive" : "Archive", systemImage: archive ? "tray.and.arrow.up" : "archivebox") {
                                        store.setArchived(p, !archive)
                                    }
                                    .tint(Brand.accent)
                                }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle(archive ? "Archive" : "Carton")
            .navigationDestination(for: Parcel.self) { Detail(parcel: $0) }
            .toolbar { if !archive { Button("Add", systemImage: "plus") { adding = true } } }
            .sheet(isPresented: $adding) { AddSheet() }
            .refreshable { await store.refreshAll() }
            .task { await store.refreshAll() }
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
                Text(parcel.name.isEmpty ? parcel.number : parcel.name).font(.headline).lineLimit(1)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
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
                Text(d <= 0 ? "Today" : "\(d)").font(.system(size: d <= 0 ? 17 : 32, weight: .semibold, design: .rounded))
                if d > 0 { Text(d == 1 ? "day" : "days").font(.caption).foregroundStyle(.secondary) }
            }
            .foregroundStyle(Brand.accent)
            .frame(minWidth: 48)
        }
    }
}

struct Detail: View {
    @Environment(Store.self) private var store
    let parcel: Parcel

    private var status: Status? { store.statuses[parcel.number] }

    var body: some View {
        List {
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
        .listStyle(.insetGrouped)
        .navigationTitle(parcel.name.isEmpty ? "Package" : parcel.name)
        .navigationBarTitleDisplayMode(.inline)
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
                    .textInputAutocapitalization(.characters).autocorrectionDisabled()
                TextField("Name (optional)", text: $name)
                if bad { Text("That doesn't look like a UPS tracking number.").foregroundStyle(.red) }
            }
            .navigationTitle("Add package")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { if store.add(text, name: name) { dismiss() } else { bad = true } }
                }
            }
            .onAppear {  // clipboard detect
                if let c = UIPasteboard.general.string, Store.parse(c) != nil { text = c }
            }
        }
        .presentationDetents([.medium])
    }
}
