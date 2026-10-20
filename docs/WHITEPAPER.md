# Carton Technical Whitepaper

**v0.1** | October 2026

Carton is a package tracker that answers one question first: how many days until it arrives. It works without an account, without API keys and without a server of its own.

## The core mechanic
Carriers guard their tracking APIs. UPS issues keys only to holders of a UPS shipping account, and its public site blocks scripted requests. A person with a browser, though, can always read their own tracking page. Carton does exactly that: it opens UPS's tracking page in a hidden WebKit view on the user's phone, waits for the page's scripts to render the result, and reads the text a person would see.

`UPSPage.parse` turns that text into a status. The current step is the one the progress bar marks "active". The delivery date sits under "Estimated delivery", or "Delivered On" once it lands. Dates come as "Tuesday, October 27", "10/27/2026", "Today" or "Tomorrow", and all four resolve to a day, with a January date seen in December rolling into the next year. The countdown is whole days from today to that day.

## Storage and sync
The list is a small JSON array in UserDefaults, mirrored to NSUbiquitousKeyValueStore when sync is on. Devices merge by tracking number. Nothing leaves the user's devices except page loads to ups.com.

## Limits
The reader depends on UPS's wording. A test (`tests/ParseCheck.swift`) holds real captured page text, so a change on UPS's side shows up as a failing check rather than a silent wrong date. The official API client in `cli/ups.py` is the drop-in upgrade when keys are available.

MIT License, 2026 Joshua Trommel.
