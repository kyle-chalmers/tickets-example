# tickets-example

> 🌐 **[KC Labs](https://www.kclabs.ai/)** | 📺 **[Kyle Chalmers Data & AI YouTube](https://youtube.com/@kylechalmersdataai)**

A public demo of **[Ticketwright](https://github.com/kyle-chalmers/ticketwright)**. This repo is
intentionally unconfigured. The point is to configure it live with Ticketwright and watch a
ticket-driven data-work repo take shape.

## Configure it

Install the plugin (once):

```bash
claude plugin marketplace add kyle-chalmers/ticketwright
claude plugin install ticketwright@ticketwright
```

Then open Claude Code in this repo and run:

```
/ticketwright:setup          # detects your tools, asks up to five questions, writes the config + scaffolding
/ticketwright:ticket TW-1    # start working a ticket
```

`setup` is what fills this repo in: the tool config (`.claude/config/stack.yaml`), global rules
(`AGENTS.md`), the self-maintaining `tickets/` index, and the folder structure.

## License

MIT. See [`LICENSE`](LICENSE).
