---
title: "Hello World"
date: 2024-03-24T15:00:00+01:00
slug: "hello-world"
---

## Introduction

In the ever-evolving world of distributed systems, staying up-to-date with the latest research, tools, and practices is crucial. 
As an experienced engineer, researcher and distributed systems enthusiast, I find immense value in sharing my insights and reflections with the community. 
Inspired by Murat Demirbas' blog post on ["Why I Blog"](http://muratbuffalo.blogspot.com/2024/03/why-i-blog.html), 
I have decided to embark on my own blogging journey, the main goal is to write to myself as I share and use it as a way to organize my own thoughts.

## Formal Theory, Validation, and Testing of Distributed Systems

One area that has always fascinated me is the intersection of formal theory, validation, and testing in distributed systems. 

Recently, I came across a remarkable company called Antithesis, which is working on a cutting-edge tool for deterministic simulation testing. 
Their work has the potential to revolutionize the way we build and test distributed systems. 
I heard about the Simulation Testing framework ideas from FoundationDB in the past 
(I recall mainly this [Strange Loop presentation](https://www.youtube.com/watch?v=4fFDFbi3toc) almost 10 years ago). 
However, now Antithesis has developed a finished product and discusses their work in detail in their blog post titled ["Is Something Bugging You?"](https://antithesis.com/blog/is_something_bugging_you/). 
The acceptance of their approach by the community and its impact on existing platforms like [CockroachDB](https://www.cockroachlabs.com/blog/demonic-nondeterminism/), 
[TigerBeetle](https://twitter.com/jorandirkgreef/status/1765963724559429661), and [WarpStream](https://www.warpstream.com/blog/deterministic-simulation-testing-for-our-entire-saas) 
may be the beginning of a seismic shift for crucial advancements in distributed systems validation.

The importance of improving software quality in distributed systems is evident. 
Individuals such as [Aphyr](https://aphyr.com/about) have demonstrated the need for enhancements in various realms, including databases and the [crypto space](https://jepsen.io/analyses/radix-dlt-1.0-beta.35.1). 
Additionally, the database systems and distributed stream processing communities have shown increasing interest in quality improvements, 
as highlighted in the insightful blog post ["Internal Consistency in Streaming Systems"](https://www.scattered-thoughts.net/writing/internal-consistency-in-streaming-systems).

## The Importance of Exploring Our Literature

Learning from the past is crucial in any field, and distributed systems are no exception. 
Personally, I find immense value in exploring older blog posts and literature. 
For instance, I have started participating in a book club led by Alex, the author of the great ["Database Internals"](https://www.databass.dev/) book, where people engage in thought-provoking discussions, 
this time about Jim Gray's classic work on ["Transaction Processing"](https://www.oreilly.com/library/view/transaction-processing/9780080519555/). 
I really recommend participating of his Discord community. These resources not only provide a wealth of knowledge but also foster a community where we can exchange ideas.

## Expanding Skill Set: TLA+ and Formal Proofs

To broaden my skill set, I have been dedicating time to learn TLA+ using Hillel Wayne's accessible guide, ["Practical TLA+"](https://link.springer.com/book/10.1007/978-1-4842-3829-5). 
TLA+ is a powerful tool for modeling and verifying distributed systems, and I aim to apply this knowledge by prototyping simple proofs in projects using languages like Golang or Rust. 
It's worth mentioning that even the White House now encourages writing formal proofs for software, as discussed in Hillel Wayne's LinkedIn post 
on the ["Final ONCD Technical Report"](https://www.linkedin.com/posts/hillel-wayne_final-oncd-technical-reportpdf-activity-7169034342977974272-QEzI).

## Balance Between Formal Proofs and Deterministic Simulation Testing

While formal proofs have gained recognition for their role in building secure systems, it's essential to note that they are not a universal solution. 
Cockroach Labs' blog post titled ["Antithesis of a One-in-a-Million Bug: Taming Demonic Nondeterminism"](https://www.cockroachlabs.com/blog/demonic-nondeterminism/) provides a powerful reminder of the crucial role deterministic simulation testing 
plays in ensuring the reliability and stability of systems. This realization highlights the need for further research to bridge the gap between design and implementation, ultimately leading to the development of safer distributed systems.

## Até logo 

Embarking on the journey of distributed systems is a lifetime endeavor that continually presents new challenges and opportunities for growth. 
Through blogging, I aim to share a bit more to the community while I write to understand pieces of the world myself. 
In the end, reading and writing are still the best ways of learning about yourself and reasoning about our world. Γνῶθι σαυτόν.
