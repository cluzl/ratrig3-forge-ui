# RatRig FORGE UI

A RatRig-focused Mainsail v2.18.2 fork with an operator-first dashboard, liquid-glass visual system, full stock-page viewability, safe thermal/output controls, object exclusion, live tuning, and printer-health integration.

## One-command installation

Run this on the printer host as its normal Klipper user:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/cluzl/ratrig3-forge-ui/77a11e2719f5f383805a358c550f4ba3b071cb4a/install.sh)"
```

The installer:

- downloads the latest prebuilt release and verifies its SHA-256 checksum;
- backs up the existing `~/mainsail` directory;
- preserves printer-local `config.json` and `oe/` assets;
- atomically swaps the static UI;
- reloads nginx when passwordless sudo is available;
- never restarts Klipper or Moonraker.

If Mainsail lives elsewhere:

```bash
FORGE_UI_TARGET=/path/to/mainsail bash -c "$(curl -fsSL https://raw.githubusercontent.com/cluzl/ratrig3-forge-ui/77a11e2719f5f383805a358c550f4ba3b071cb4a/install.sh)"
```

## Rollback

The installer prints the timestamped backup path. To roll back:

```bash
mv ~/mainsail ~/mainsail.failed && mv ~/mainsail.backup-YYYYMMDD-HHMMSS ~/mainsail
```

Then reload nginx or refresh the page. Klipper and Moonraker do not need a restart.

## Build from source

```bash
npm ci
npm run lint
npm run test:unit
npm run build
```

Built static assets are written to `dist/`. GitHub releases contain a ready-to-install `forge-ui.tar.gz`, so target printers do not need Node.js.

## Compatibility

- Mainsail base: v2.18.2
- Klipper + Moonraker
- Tested on RatRig V-Core 3
- Other Klipper printers are supported, but printer-specific macros and telemetry appear only when exposed by that printer.

## License

GPL-3.0, inherited from Mainsail. This repository contains the complete corresponding source for its published build.
