# Evidence behind writing-readable-code

Research done on 2026-10-07. Each line gives the rule, the evidence, and its strength.
Readability models measure what people judge readable. Comprehension studies measure what
people understand. The two do not always agree, so comprehension evidence counts for more.

## Strong or moderate evidence

| Rule | Evidence | Source |
|---|---|---|
| Full words in names | Professionals found defects 19% faster with full words than with letters or abbreviations. | [Hofmeister et al. 2017][hofmeister] |
| Fix misleading names first | A misleading name was worse than a single letter. Parameter names mattered most. Small study (n=9). | [Avidan & Feitelson 2017][avidan] |
| Less nesting, fewer flow breaks | Cognitive Complexity correlates with comprehension time (r = 0.54). No threshold is validated. | [Muñoz Barón et al. 2020][cognitive] |
| Flatten with guard clauses | Less nesting reduced reading time and raised confidence (n=275). | [Lubo Argumedo][nesting] |
| Split compound conditions; avoid negations | Errors grew with the number of conditions. Some negations made predicates harder (n=222). | [Ajami et al. 2017][ajami] |
| No side effects inside expressions | 15 of 19 confusing C patterns confirmed, with medium to very large effect sizes. | [Gopstein et al. 2017][atoms] |
| Short lines, few identifiers per line, blank lines between steps | Strongest predictors of judged readability. Identifier length had no predictive power. | [Buse & Weimer 2010][buse] |
| One topic per block; comments consistent with names | Textual features add accuracy on top of structure. | [Scalabrino et al. 2018][scalabrino] |
| Few things to hold in mind at once | Short-term memory holds about 4 chunks. | [Cowan 2001][cowan] |

## Weak, mixed, or contested

- **Comments:** the effect ran from -30% to +34% per snippet. People like comments more than comments help them. [Abdelsalam et al. 2025][comments]
- **Abbreviations vs full words:** some studies find no difference. [Never Work in Theory][abbrev]
- **camelCase vs snake_case:** experienced readers are barely affected. Follow the language convention. [Binkley et al. 2013][case]
- **Expert idioms:** comprehension was equal for novices; readability is partly familiarity. [Wiese et al. 2019][wiese]
- **AI code overall:** static metrics show small differences from human code [Atlassian][atlassian], and a registered trial found no significant maintenance cost [Borg et al.][borg]. The problem is specific patterns, not AI code in general.

## Specific AI-code patterns

- Top LLM readability issues: excessive complexity, redundant comments, inconsistent style, redundant variables, hallucinated APIs. [Readability Spectrum][spectrum]
- Methods that reviewers deleted from agent PRs were longer, had longer names, and were more complex. [What to Cut?][cut]
- Copy/paste rose and refactoring fell during AI adoption (correlation only). [GitClear 2025][gitclear]
- Code smells were over 90% of issues in LLM Java output. [Sonar][sonar]

## Practitioner guidance

- Deep modules, comments for what the code cannot say, define errors out of existence; disagreement with Clean Code on tiny functions. [Ousterhout vs Martin][aposd]
- Tiny functions plus shared state hide data flow. [qntm][qntm]
- Keep behavior visible in one place. [Locality of Behaviour][lob]
- Nesting at most 2 levels; names without filler words; comment why, not what. [Google: nesting][g-nest] · [Google: naming][g-name] · [Google: comments][g-comment]
- Clear is better than clever. [Go proverbs][go] · [Kernighan][kernighan]
- Guard clauses, explaining variables, cohesion order; split structure and behavior changes. [Tidy First? review][tidy]
- Comments tell you why. [Atwood][atwood] · [Stack Overflow][so-comments]

[hofmeister]: https://www.se.cs.uni-saarland.de/publications/docs/HoSeHo17.pdf
[avidan]: https://cris.huji.ac.il/en/publications/effects-of-variable-names-on-comprehension-an-empirical-study/
[cognitive]: https://arxiv.org/pdf/2007.12520
[nesting]: https://repositorio.unal.edu.co/items/a404ed92-9f9e-457f-8aca-0b128ea70176/full
[ajami]: https://www.cs.huji.ac.il/~feit/papers/Complexity17ICPC.pdf
[atoms]: https://atomsofconfusion.com/papers/understanding-misunderstandings-fse-2017.pdf
[buse]: https://web.eecs.umich.edu/~weimerw/p/weimer-tse2010-readability-preprint.pdf
[scalabrino]: https://www.cs.wm.edu/~denys/pubs/JSEP'18-ReadabilityPaper.pdf
[cowan]: https://memory.psych.missouri.edu/assets/doc/articles/2001/cowan-bbs-2001.pdf
[comments]: https://www.se.cs.uni-saarland.de/publications/docs/APB+25.pdf
[abbrev]: https://neverworkintheory.org/2021/08/09/abbreviated-vs-full-names.html
[case]: https://www.cs.kent.edu/~jmaletic/cs69995-PC/papers/EMSE12.pdf
[wiese]: https://acelab.berkeley.edu/wp-content/papercite-data/pdf/autostyle-readability-comprehension-icse2019.pdf
[atlassian]: https://arxiv.org/html/2501.11264v2
[borg]: https://arxiv.org/abs/2507.00788v3
[spectrum]: https://arxiv.org/html/2605.13280v1
[cut]: https://arxiv.org/html/2602.17091
[gitclear]: https://www.gitclear.com/ai_assistant_code_quality_2025_research
[sonar]: https://www.sonarsource.com/blog/the-coding-personalities-of-leading-llms-gpt-5-update/
[aposd]: https://github.com/johnousterhout/aposd-vs-clean-code
[qntm]: https://qntm.org/clean
[lob]: https://htmx.org/essays/locality-of-behaviour/
[g-nest]: https://testing.googleblog.com/2017/06/code-health-reduce-nesting-reduce.html
[g-name]: https://testing.googleblog.com/2017/10/code-health-identifiernamingpostforworl.html
[g-comment]: https://testing.googleblog.com/2017/07/code-health-to-comment-or-not-to-comment.html
[go]: https://go-proverbs.github.io/
[kernighan]: https://www.linusakesson.net/programming/kernighans-lever/
[tidy]: https://henrikwarne.com/2024/01/10/tidy-first/
[atwood]: https://blog.codinghorror.com/code-tells-you-how-comments-tell-you-why/
[so-comments]: https://stackoverflow.blog/2021/12/23/best-practices-for-writing-code-comments/
