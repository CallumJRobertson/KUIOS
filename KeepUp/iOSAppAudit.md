# iOS App UX & Performance Audit

## UX Opportunities
- **Remove debug counters from user-facing Updates feed.** The Updates screen still exposes developer diagnostics (tracked counts and the raw list of tracked shows) beneath the carousels, which crowds the page and can leak personal media history. Replace this block with a concise empty-state CTA (e.g., "Add shows to start tracking" with a button to search).【F:KeepUp/YourUpdatedView.swift†L92-L140】
- **Strengthen empty states with actions.** When there are no upcoming items, the Updates view shows a passive `ContentUnavailableView` without a way to add shows. Add a button that opens search or the Library tab so users can immediately track something.【F:KeepUp/YourUpdatedView.swift†L77-L90】
- **Surface watch-provider logos progressively.** The detail screen fetches provider logos for every provider without placeholders sized to the final frame, which can cause layout jumps on slow networks. Apply fixed sizing and shimmering placeholders while logos load to keep the tile grid stable.【F:KeepUp/ShowDetailView.swift†L237-L279】

## Performance & Smoothness
- **Reduce formatter churn in recent-release checks.** `loadRecentReleases` builds new `DateFormatter` instances in each task and again during sorting. Hoist a single formatter outside the task group or reuse a static formatter to cut CPU overhead and improve scroll smoothness on larger libraries.【F:KeepUp/AppState.swift†L270-L323】
- **Avoid recreating TMDB clients for every detail fetch.** `ShowDetailView` constructs a new `TMDBClient` for details, trailers, watch providers, and status calls, which duplicates URLSession setup and limits connection reuse. Pass the shared client from `AppState` (or cache one in the view) and fire the requests in a task group to parallelize network work and shorten time-to-render.【F:KeepUp/ShowDetailView.swift†L334-L405】【F:KeepUp/TMDBClient.swift†L4-L171】
