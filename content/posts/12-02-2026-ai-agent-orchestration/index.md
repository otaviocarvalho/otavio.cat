---
title: "Our AI Orchestration Frameworks Are Reinventing Linda (1985)"
date: 2026-02-12T10:00:00+01:00
slug: "ai-orchestration-reinventing-linda"
---

AI coding agents have a coordination problem. How do multiple agents share work without stepping on each other? How do they persist state across sessions? How do they claim tasks atomically?

The community is solving this independently: Yegge's **[Beads](https://steve-yegge.medium.com/introducing-beads-a-coding-agent-memory-system-637d7d92514a)** (git-backed), Huntley's **[Ralph Wiggum](https://github.com/ghuntley/how-to-ralph-wiggum)** (persistent loops), Anthropic's **[Agent Teams](https://code.claude.com/docs/en/agent-teams)**, Turso's **[AgentFS](https://turso.tech/blog/agentfs)** (SQLite), **[OpenClaw](https://github.com/openclaw/openclaw)** (filesystems). Different substrates, but they're converging on identical patterns.

We've built this many times since 1985.

These projects seem deeply linked to tuple spaces. David Gelernter published the foundational theory in 1985 (yes, [the same Gelernter recently barred from teaching at Yale](https://www.cnbc.com/2026/02/11/epstein-files-yale-david-gelernter-classeds.html) after appearing in the Epstein files).

## What's Actually Happening

The current AI agent coordination stack, assembled over the last year, looks like this:

**[Goose](https://github.com/block/goose)** (Block, 2025) is an open-source framework that orchestrates teams of specialized AI agents (Planner, Project Manager, Architect) with subagent capabilities. It reads and writes files, runs code and tests, and coordinates workflows in real time. Now part of the Linux Foundation's [Agentic AI Foundation](https://www.linuxfoundation.org/press/linux-foundation-announces-the-formation-of-the-agentic-ai-foundation).

**[Beads](https://steve-yegge.medium.com/introducing-beads-a-coding-agent-memory-system-637d7d92514a)** (Steve Yegge, 2025) is a git-backed issue tracker for AI agents. Tasks are stored as JSONL records in a `.beads/` directory. Agents query for ready work via pattern matching (`bd ready`), atomically claim tasks (`bd claim`), and close them when done. Dependencies form a DAG. The whole thing travels with your code in git.

**[Ralph Wiggum](https://github.com/ghuntley/how-to-ralph-wiggum)** (Geoffrey Huntley, 2025) is a bash loop that runs an AI coding agent repeatedly until a completion condition is met. The agent reads its task list, picks something to work on, implements it, and the loop restarts with fresh context. State persists in the filesystem and git history between iterations.

**[OpenHands](https://openhands.dev/)** (formerly OpenDevin) has the most formally articulated coordination model, emerging from academia ([ICLR 2025 paper](https://arxiv.org/abs/2407.16741)) with multi-agent research in mind. Its core primitive is an **event stream** — a chronological, append-only log of actions and observations where each observation includes a `cause` field pointing to the originating action ID, creating a happens-before relation. Agents operate as perception-action loops: read the event stream history, produce the next action, get the observation appended. Multi-agent coordination happens via `AgentDelegateAction`, enabling hierarchical delegation where a parent agent spawns a child in the same Docker sandbox. The child gets its own event stream segment and returns results via fork-join. The event stream is architecturally the closest thing to a proper log-structured tuple space, though it lacks associative matching, blocking reads, or atomic consumption.

**[AgentFS](https://turso.tech/blog/agentfs)** (Turso, 2025) provides a SQLite-based state management layer with filesystem, key-value, and audit trail interfaces. All agent state lives in a single queryable SQLite database, enabling portability and SQL-based debugging.

**[Agent Teams](https://code.claude.com/docs/en/agent-teams)** (Anthropic, 2025) enables multi-agent coordination through shared task lists, inter-agent mailboxes, and team-aware routing primitives.

**[OpenClaw](https://github.com/openclaw/openclaw)** ([Peter Steinberger](https://steipete.me/), 2025) is an open-source personal AI assistant that coordinates agents through shared filesystems, session-based routing, and heartbeat polling. Agents communicate via filesystem state and scheduled wake cycles.

These tools work. People are shipping real code with them. The community energy is genuine and the engineering is practical. I have no quarrel with any of that.

But many of us don't yet realize we're working within a research tradition that's forty years old, and that the problems we're hitting — and the problems we haven't hit yet — were catalogued extensively between 1985 and 2005.

## Linda in Sixty Seconds

In 1979, David Gelernter was a PhD student at SUNY Stony Brook, frustrated that parallel programming required processes to know about each other. He wanted processes that communicated by dropping data into a shared pool and picking data out by content matching — not by addressing specific recipients.

His PhD work became a 1985 TOPLAS paper, ["Generative Communication in Linda,"](https://dl.acm.org/doi/10.1145/2363.2433) which introduced the **tuple space**: a shared associative memory where:

- **`out(t)`** puts a tuple into the space
- **`in(template)`** atomically removes a matching tuple (blocks if none exists)
- **`rd(template)`** reads a matching tuple without removing it
- **`eval(t)`** creates a "live" tuple that computes before becoming data

The critical properties were:

1. **Spatial decoupling**: processes don't know who they're talking to
2. **Temporal decoupling**: producer and consumer don't need to be alive at the same time
3. **Associative access**: you retrieve by *content pattern*, not by address
4. **Atomic operations**: `in()` removes exactly one match, atomically — no races

And the deepest insight, one that separated Linda from everything that came before: **coordination is orthogonal to computation**. The thing doing the work and the thing organizing the work are separate concerns with separate vocabularies. You don't weave coordination into your computation language. You layer it alongside.

## The Correspondence Table

| **Linda (1985)** | **Modern AI Agent Orchestrators (2025)** |
|:---|:---|
| Tuple space | Shared data store (Beads: `.beads/` in git; AgentFS: SQLite; OpenClaw: filesystem) |
| `out(t)` — insert tuple | Create task (Beads: `bd create`; AgentFS: SQL INSERT; OpenClaw: write files) |
| `in(template)` — atomic destructive read | Claim task (Beads: `bd claim`; agent loops: pick from backlog) |
| `rd(template)` — non-destructive read | Query available work (Beads: `bd ready`; AgentFS: SQL SELECT; OpenClaw: read task boards) |
| Template matching | Status/priority filtering, SQL WHERE clauses, dependency checking |
| `eval(t)` — live tuple | Agent loop iteration (Ralph, OpenClaw heartbeats) |
| Tuple persistence | Git commits (Beads), SQLite database (AgentFS), filesystem state (OpenClaw) |
| Process creation | Spawn agent contexts (Ralph, OpenClaw sessions) |
| Blocking on match | Polling loops (Ralph iterations, OpenClaw heartbeats) — no blocking |

The mapping is close enough that you could describe these systems as "Linda implemented over git, SQLite, or filesystems, with status-based matching and dependency DAGs."

## The Forty Years We're Skipping

We're energetically rediscovering problems that the tuple space research literature solved, partially solved, or at least carefully characterized. Here are the ones I see coming:

### The Atomic Claim Problem

Linda's `in()` is atomic by definition: exactly one process gets each matching tuple, and the removal is indivisible. This is what makes the "bag of tasks" pattern work without a central scheduler.

Modern systems struggle with this. Beads' `bd claim` is a read-then-write on a JSONL file in git — two agents can claim the same task simultaneously. OpenClaw's filesystem-based coordination has similar race conditions when multiple agents check task boards concurrently. The JSONL merge strategy papers over this, but it's not safe. This is a [distributed consensus problem](https://en.wikipedia.org/wiki/Consensus_(computer_science)) (a coordination problem), and the tuple space literature spent a decade on it.

[PLinda](https://ieeexplore.ieee.org/document/336905) (1994) solved it with checkpointing. [FT-Linda](https://eecs.wsu.edu/~bakken/ftlinda-TPDS.pdf) (Bakken & Schlichting, 1995) provided stable tuple spaces with atomic execution via replication and atomic multicast. [JavaSpaces](https://cseweb.ucsd.edu/groups/csag/html/teaching/cse291s03/Readings/microsystems98javaspaces.pdf) (Sun, 1998) solved it with transactions. [DEPSPACE](https://www.di.fc.ul.pt/~bessani/publications/eurosys08-depspace.pdf) (2008) and [LBTS](https://www.dpss.inesc-id.pt/~mpc/pubs/lbts-tc-final.pdf) solved it while tolerating Byzantine faults. These solutions exist.

### The Polling Problem

Linda's `in()` *blocks* until a matching tuple appears. This is implicit synchronization — the consumer sleeps until work exists.

Modern agent systems poll. Ralph Wiggum runs iterations checking for work. OpenClaw uses heartbeat polling (default 30 min wake cycles). Every check that finds no work wastes tokens and API calls. The community's advice is to cap iterations or increase polling intervals.

The [Event Heap](https://graphics.stanford.edu/papers/eheap-jss/eheap-jss.pdf) project at Stanford (2002) documented this problem precisely: "A drawback of the basic tuplespace model is that it only supports polling. Tuples placed into the tuplespace and removed between successive polls by a process will not be seen by that process." They added event subscriptions and query registration. [TSpaces](http://bitsavers.informatik.uni-stuttgart.de/pdf/ibm/IBM_Systems_Journal/373/wyckoff.pdf) at IBM added reactive notifications. This was already a solved problem by 2003.

### The Context Rot Problem

When agent loops run long enough, the AI agent's context window compacts. It forgets its earlier work. Persistent storage helps — Beads stores task state in git, OpenClaw uses filesystem memory, AgentFS maintains structured state in SQLite with full audit trails. But the agent's *working memory* still decays.

This is the tuple space equivalent of the **garbage collection and tuple aging problem**. JavaSpaces introduced *leases* — tuples expire after a TTL unless renewed. The [Fading Tuple Spaces](https://pure.york.ac.uk/portal/en/publications/the-fading-concept-in-tuple-space-systems-2) paper (2006) formalized "memory decay" as a first-class concept. Modern systems like Beads' `bd compact` command (which summarizes old closed tasks) are reinventing lease-based tuple aging.

### The Flat Space Problem

Early Linda had one global tuple space. Everything was visible to everyone. This doesn't scale.

Gelernter himself recognized this by 1989 and introduced Multiple Tuple Spaces. The next fifteen years produced [KLAIM](http://eprints.imtlucca.it/351/1/tse_1998a.pdf) (explicit localities and access control), [SecSpaces](https://www.sciencedirect.com/science/article/pii/S1571066105803755) (capability-based security), [LIME](https://es-static.fbk.eu/people/murphy/Papers/icdcs01.pdf) (mobile tuple spaces that merge and split as devices move), and [XVSM](https://link.springer.com/chapter/10.1007/978-3-540-88479-8_45) (user-definable coordination laws).

Current systems have similar constraints. Beads has one flat space per project. OpenClaw's shared filesystem is global per workspace. AgentFS gives each agent its own SQLite database, which provides isolation but not coordination between agents. The first time someone tries to run multiple agent teams with different visibility requirements on shared state, they'll need scoped spaces. The literature has the taxonomy ready.

### The Distribution Problem

Git-backed systems like Beads use DVCS as their distribution mechanism. This is genuinely novel — no tuple space implementation used a DVCS as the replication layer. Some implementations used database backends (like TSpaces) which had WAL (Write-Ahead Logs) implicitly, but WAL was never consciously adopted as a coordination mechanism — it was just an implementation detail of the SQL databases they built upon, at least from what I could grasp in this research.

Git means eventual consistency with last-write-wins merge semantics. This is fundamentally different from classic tuple spaces — but maybe that's because [CRDTs](https://en.wikipedia.org/wiki/Conflict-free_replicated_data_type) (Conflict-free Replicated Data Types) weren't a thing back then? — As a sidetrack, since I am a distributed systems enthusiast from the 2000s, I need a mandatory mention to [Riak/Basho's history](https://christophermeiklejohn.com/erlang/lasp/2019/03/08/monotonicity.html). And while you are at it, please read [the rest of Chris Meiklejohn's research work](https://christophermeiklejohn.com/research.html) too, you will not regret. Now back to the topic — Could CRDTs provide a path to reconciling git's eventual consistency with tuple space semantics? It seems genuinely unexplored territory.

Linda's `in()` operation is linearizable — exactly one process atomically claims each tuple, and this property holds even across distributed replicas. Modern systems sacrifice this atomicity for availability. You can work offline (Beads with git), maintain portable state (AgentFS with SQLite), or coordinate via shared filesystems (OpenClaw). Conflicts are resolved with eventual consistency. The [PACELC theorem](https://www.cs.umd.edu/~abadi/papers/abadi-pacelc.pdf) provides a framework for thinking about these tradeoffs: during partitions, choose between availability and consistency; during normal operation, choose between latency and consistency. There's a whole corpus of research on [consistency models](https://jepsen.io/consistency) to help evaluate these tradeoffs depending on the flavor of your final solution.

This isn't wrong — it might even be the right choice for AI agent coordination where availability and local-first operation matter more than strict consistency. But the tradeoffs are well-understood in the distributed systems literature, and knowing which tradeoff you've made is important for knowing when your system will break.

## What the Literature Offers That We're Missing

### Formal Semantics

Linda has a [process calculus](https://en.wikipedia.org/wiki/Process_calculus). There are [bisimulation](https://en.wikipedia.org/wiki/Bisimulation) equivalences, [failure semantics](https://www.pst.ifi.lmu.de/Lehre/fruhere-semester/sose-2013/formale-spezifikation-und-verifikation/intro-to-pa.pdf), net semantics based on [contextual Petri nets](https://www.researchgate.net/publication/222709028_On_the_Expressiveness_of_Linda_Coordination_Primitives). You can *prove things* about coordination protocols specified in the Linda model.

Current agent orchestrators have no formal semantics. When someone asks "can two agents ever deadlock waiting on each other's tasks?" the answer is "try it and see." With a formal model, you could check this in [Alloy](https://alloytools.org/) in about ten minutes.

### The Coordination Languages Taxonomy

Gelernter and Carriero's 1992 CACM paper ["Coordination Languages and Their Significance"](https://cacm.acm.org/research/coordination-languages-and-their-significance/) established that coordination is a distinct language design concern, as fundamental as control flow or data structures. This spawned a field. There are international conferences on coordination models ([COORDINATION](https://link.springer.com/conference/coordination), [running since 1996](https://link.springer.com/book/10.1007/3-540-61052-9)). There's a [coordination model](https://www.sciencedirect.com/topics/computer-science/coordination-model) taxonomy that maps neatly onto the patterns the AI agent community is developing ad-hoc.

These systems describe [coordination patterns](https://arxiv.org/html/2508.12683) that have formal names, properties, and known failure modes in this literature — we are reinventing the wheel, as frequently happens in our industry.

### Spatiotemporal Extensions

The modern frontier of tuple space research is [spatiotemporal tuples](https://inria.hal.science/hal-03387837v1/document) — tuples that exist within a geographic region and a time window, formalized using [aggregate computing](https://www.sciencedirect.com/science/article/pii/S235222081930032X). This is directly relevant to the AI agent use case: an agent's "discovery" (a bug it found while working on something else) should be visible to nearby agents (those working on related code) and should decay over time (it's less relevant a week later). Beads' priority levels are a primitive version of this.

## What's Genuinely New

To be fair, there are aspects of the AI agent coordination problem that didn't exist in the tuple space era:

**Non-deterministic workers.** Linda assumed workers were deterministic programs. LLM agents are stochastic — the same prompt produces different behavior. This means coordination protocols need to be robust to arbitrary worker behavior, not just crash failures. The "deterministically bad in an undeterministic world" philosophy of Ralph Wiggum is a real insight about designing for this.

**Context windows as volatile implicit state.** A tuple space process carries its state in local variables that persist for its lifetime. An LLM agent carries implicit state in its context window that can be silently compacted at any time, *and the agent doesn't know what it forgot*. This is a new failure mode that has no analogue in the classical literature. Modern models like [Claude Opus 4.6](https://www.anthropic.com/news/claude-opus-4-6) have extended context windows, but compaction remains an architectural reality.

**Git as coordination substrate.** Using a DVCS as the replication layer for a tuple space is novel. [Persistent Linda](https://link.springer.com/chapter/10.1007/3-540-55160-3_37) (1992) used append-only transaction logs for durability. Git shares this property but adds branching, full history, and semantic merges — capabilities that enable asynchronous collaboration across network partitions.

Agents can fork the tuple space, work offline, and merge later. But this creates unexplored problems: What does it mean for a tuple to be "consumed" when agents see different versions of the space? How do you maintain atomicity guarantees when the substrate is eventually consistent? The tension between git's optimistic concurrency and Linda's atomic primitives hasn't been formally resolved.

**Cost-aware coordination.** Every coordination operation costs money in AI agent systems. Polling for work wastes API tokens. Reading task state costs tokens. This fundamentally changes coordination patterns — you can't just "check for work every second" like a traditional process would. The economic constraints on coordination operations didn't exist in the tuple space era.

**Human-in-the-loop workflows.** AI agents often need human approval, clarification, or feedback mid-task. Traditional tuple spaces assumed autonomous processes that could complete tasks without external input. Modern agent systems need coordination primitives for "pause and wait for human" — this is a new coordination pattern.

**Stateless ephemeral workers.** LLM agents are typically accessed as API services, not long-running processes with persistent memory. Each "invocation" is a fresh, stateless call. Traditional tuple space workers were assumed to be running processes that maintained local state between tuple operations. This changes how you think about coordination — the worker itself can disappear between operations.

## The Ask

I'm not arguing that we should stop building tools and read forty-year-old papers instead. The tools work, the energy is productive, and the problems we're solving are real.

But I am convinced that there's a body of work that could save us years of rediscovery. Specifically:

1. **Read Gelernter's 1985 paper.** It's 32 pages, beautifully written, and the core ideas are immediately applicable. ["Generative Communication in Linda,"](https://dl.acm.org/doi/10.1145/2363.2433) TOPLAS 7(1).

2. **Read Carriero & Gelernter 1992.** ["Coordination Languages and Their Significance,"](https://cacm.acm.org/research/coordination-languages-and-their-significance/) CACM 35(2). This is the paper that frames coordination as a first-class design concern. It will change how you think about the problem.

3. **Look at JavaSpaces.** Freeman, Hupfer & Arnold's 1999 book [*JavaSpaces: Principles, Patterns, and Practice*](https://archive.org/details/javaspacesprinci00eric) contains patterns (Master-Worker, Replicated Worker, Command pattern) that map directly onto current AI agent architectures.

4. **Consider formal modeling.** [Alloy 6](https://alloytools.org/) can model your coordination protocol in an afternoon and find race conditions you won't discover in months of testing. [TLA+](https://lamport.azurewebsites.net/tla/tla.html) can verify temporal properties like "every task eventually completes or times out." AWS and other companies building critical infrastructure are increasingly using formal model tools (LLMs work surprisingly well with them too) — see Marc Brooker's ["Why You Should Learn Formal Methods"](https://brooker.co.za/blog/2015/03/29/formal.html), which links to the public CACM paper ["How Amazon Web Services Uses Formal Methods"](https://cacm.acm.org/research/how-amazon-web-services-uses-formal-methods/). These methods are accessible and free.

The deepest irony isn't that we're reinventing tuple spaces. It's that Gelernter's original motivation (his *research* motivation, as it appears from the outside — not the Epstein-related one) — decoupling coordination from computation so that heterogeneous processes can collaborate through shared structured data — is *exactly* the problem statement of AI agent orchestration. The words are different. The bash scripts are new. The underlying mathematics is the same.

The tuple space research community spent forty years on this. The least we can do is check their work before we redo it.

## A Note on This Post

The core idea is mine — I've been thinking about this connection for quite a while. The idea recently gained urgency after I used [Beads](https://steve-yegge.medium.com/introducing-beads-a-coding-agent-memory-system-637d7d92514a) and [Gas Town](https://steve-yegge.medium.com/welcome-to-gas-town-4f25ee16dd04) very productively and finally decided to ask Claude Opus 4.6 to write this piece in a [HN](https://news.ycombinator.com/)-friendly way.

"I wrote this for three reasons": (a) to see if Claude can build a viral post out of my notes, (b) to have something to show recruiters in the near future when they inevitably ask "do you know anything about AI?", and (c) to make you lazy people read research papers. I still regret that [Adrian Colyer's blog](https://blog.acolyer.org/) isn't active anymore — has anyone heard from him? I hope he's properly enjoying his retirement, but I deeply miss his paper reviews.

Thanks to the researchers whose work informed this post, particularly the survey ["Tuple Spaces Implementations and Their Efficiency"](https://inria.hal.science/hal-01631715v1/document) (Buravlev, De Nicola, and Mezzina, 2016) and the spatiotemporal tuples work ["Tuple-Based Coordination in Large-Scale Situated Systems"](https://link.springer.com/chapter/10.1007/978-3-030-78142-2_10) (Casadei, Viroli, and Ricci, 2021).

Finally, I want to thank Steve Yegge, Geoffrey Huntley, and many others across the globe for creating a positive energy about building something new in technology — the hacking way, not the big tech way. I haven't felt that personally for quite a while in our community, and it's genuinely refreshing. After years of building cathedrals, it looks like we're all going back to open small shops in the [bazaar](http://www.catb.org/~esr/writings/cathedral-bazaar/).

## References

### Foundational Papers

- Gelernter, D. (1985). ["Generative Communication in Linda"](https://dl.acm.org/doi/10.1145/2363.2433), ACM TOPLAS 7(1)
- Gelernter, D. & Carriero, N. (1992). ["Coordination Languages and Their Significance"](https://cacm.acm.org/research/coordination-languages-and-their-significance/), CACM 35(2)

### Tuple Space Implementations

- Anderson, T. & Shasha, D. (1992). ["Persistent Linda"](https://link.springer.com/chapter/10.1007/3-540-55160-3_37)
- Bakken, D. & Schlichting, R. (1995). ["FT-Linda: Fault-Tolerant Linda"](https://eecs.wsu.edu/~bakken/ftlinda-TPDS.pdf)
- Bjornson, R. et al. (1997). ["PLinda: Parallel Linda"](https://ieeexplore.ieee.org/document/336905)
- Freeman, E., Hupfer, S. & Arnold, K. (1999). [*JavaSpaces: Principles, Patterns, and Practice*](https://archive.org/details/javaspacesprinci00eric)
- Sun Microsystems (1998). ["JavaSpaces Specification"](https://cseweb.ucsd.edu/groups/csag/html/teaching/cse291s03/Readings/microsystems98javaspaces.pdf)
- Wyckoff, P. et al. (1998). ["TSpaces"](http://bitsavers.informatik.uni-stuttgart.de/pdf/ibm/IBM_Systems_Journal/373/wyckoff.pdf), IBM Systems Journal
- Joung, Y. & Smolka, S. (2002). ["The Event Heap"](https://graphics.stanford.edu/papers/eheap-jss/eheap-jss.pdf)
- Ferscha, A. et al. (2006). ["The Fading Concept in Tuple Space Systems"](https://pure.york.ac.uk/portal/en/publications/the-fading-concept-in-tuple-space-systems-2)
- Bessani, A. et al. (2008). ["DEPSPACE: Byzantine Fault-Tolerant Coordination"](https://www.di.fc.ul.pt/~bessani/publications/eurosys08-depspace.pdf)
- Bessani, A. et al. ["LBTS: Byzantine Fault-Tolerant Tuple Space"](https://www.dpss.inesc-id.pt/~mpc/pubs/lbts-tc-final.pdf)

### Coordination Models and Extensions

- De Nicola, R. et al. (1998). ["KLAIM: A Kernel Language for Agents Interaction and Mobility"](http://eprints.imtlucca.it/351/1/tse_1998a.pdf)
- Murphy, A. et al. (2001). ["LIME: Linda in a Mobile Environment"](https://es-static.fbk.eu/people/murphy/Papers/icdcs01.pdf)
- Braghin, C. et al. (2006). ["SecSpaces: Secure Tuple Spaces"](https://www.sciencedirect.com/science/article/pii/S1571066105803755)
- Kühn, E. et al. (2008). ["XVSM: Extensible Virtual Shared Memory"](https://link.springer.com/chapter/10.1007/978-3-540-88479-8_45)
- Buravlev, I., De Nicola, R. & Mezzina, C. (2016). ["Tuple Spaces Implementations and Their Efficiency"](https://inria.hal.science/hal-01631715v1/document)
- Casadei, R., Viroli, M. & Ricci, A. (2021). ["Tuple-Based Coordination in Large-Scale Situated Systems"](https://link.springer.com/chapter/10.1007/978-3-030-78142-2_10)
- Viroli, M. et al. (2021). ["Spatiotemporal Tuples"](https://inria.hal.science/hal-03387837v1/document)
- Moore, D. J. (2025). ["A Taxonomy of Hierarchical Multi-Agent Systems: Design Patterns, Coordination Mechanisms, and Industrial Applications"](https://arxiv.org/html/2508.12683)
- [COORDINATION Conference](https://link.springer.com/conference/coordination) ([since 1996](https://link.springer.com/book/10.1007/3-540-61052-9))
- [Coordination Model Taxonomy](https://www.sciencedirect.com/topics/computer-science/coordination-model)

### Modern AI Agent Tools

- Yegge, S. (2025). ["Welcome to Gas Town"](https://steve-yegge.medium.com/welcome-to-gas-town-4f25ee16dd04)
- Yegge, S. (2025). ["Introducing Beads"](https://steve-yegge.medium.com/introducing-beads-a-coding-agent-memory-system-637d7d92514a)
- Huntley, G. (2025). ["Ralph Wiggum"](https://github.com/ghuntley/how-to-ralph-wiggum)
- Block (2025). ["Goose"](https://github.com/block/goose)
- OpenHands (2025). [OpenHands Project](https://openhands.dev/) | [ICLR 2025 Paper](https://arxiv.org/abs/2407.16741)
- Turso (2025). ["AgentFS"](https://turso.tech/blog/agentfs)
- Steinberger, P. (2025). ["OpenClaw"](https://github.com/openclaw/openclaw)
- Anthropic (2025). ["Agent Teams"](https://code.claude.com/docs/en/agent-teams) | ["Claude Opus 4.6"](https://www.anthropic.com/news/claude-opus-4-6)
- [Agentic AI Foundation](https://www.linuxfoundation.org/press/linux-foundation-announces-the-formation-of-the-agentic-ai-foundation)

### Distributed Systems Concepts

- Abadi, D. (2012). ["PACELC Theorem"](https://www.cs.umd.edu/~abadi/papers/abadi-pacelc.pdf)
- Shapiro, M. et al. ["Conflict-free Replicated Data Types (CRDTs)"](https://en.wikipedia.org/wiki/Conflict-free_replicated_data_type)
- Meiklejohn, C. (2019). ["Applied Monotonicity: A Brief History of CRDTs in Riak"](https://christophermeiklejohn.com/erlang/lasp/2019/03/08/monotonicity.html)
- Meiklejohn, C. ["Research Work"](https://christophermeiklejohn.com/research.html)
- Kingsbury, K. ["Jepsen: Consistency Models"](https://jepsen.io/consistency)
- ["Distributed Consensus"](https://en.wikipedia.org/wiki/Consensus_(computer_science))
- Viroli, M. et al. (2019). ["Aggregate Computing"](https://www.sciencedirect.com/science/article/pii/S235222081930032X)

### Formal Methods

- ["Process Calculus"](https://en.wikipedia.org/wiki/Process_calculus)
- ["Bisimulation"](https://en.wikipedia.org/wiki/Bisimulation)
- ["Failure Semantics in Process Algebra"](https://www.pst.ifi.lmu.de/Lehre/fruhere-semester/sose-2013/formale-spezifikation-und-verifikation/intro-to-pa.pdf)
- Busi, N. & Zavattaro, G. ["On the Expressiveness of Linda Coordination Primitives"](https://www.researchgate.net/publication/222709028_On_the_Expressiveness_of_Linda_Coordination_Primitives)
- [Alloy 6](https://alloytools.org/)
- Lamport, L. [TLA+](https://lamport.azurewebsites.net/tla/tla.html)
- Newcombe, C. et al. (2015). ["How Amazon Web Services Uses Formal Methods"](https://cacm.acm.org/research/how-amazon-web-services-uses-formal-methods/), CACM 58(4)
- Brooker, M. (2015). ["Why You Should Learn Formal Methods"](https://brooker.co.za/blog/2015/03/29/formal.html)

### Other Resources

- Raymond, E. S. [*The Cathedral and the Bazaar*](http://www.catb.org/~esr/writings/cathedral-bazaar/)
- Colyer, A. [The Morning Paper](https://blog.acolyer.org/)
- CNBC (2026). ["David Gelernter Barred from Teaching at Yale"](https://www.cnbc.com/2026/02/11/epstein-files-yale-david-gelernter-classeds.html)
- Yegge, S. [Personal Blog](https://steve-yegge.medium.com/)
- Huntley, G. [Personal Blog](https://ghuntley.com/)
- Steinberger, P. [Personal Blog](https://steipete.me/)
