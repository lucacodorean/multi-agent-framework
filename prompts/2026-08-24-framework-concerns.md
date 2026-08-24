# Concerns raised by human agent while reviewing the work

## Core-related questions

- If orchestration belongs to the framework's core, what's the purpose to also reiterate it in docs/conventions?
- Same goes for the rules-of-engagement.md and documentation-governance. I assume that extra mechanisms for both orchestration,
    rules-of-engagement and docs-governance be added through the framework/extensions possibility.
    They are marked as moved so I assume that they could be safely removed.

    Ensure that any references
    to these files, specifically at the knowledge-base/docs/conventions/{orchestration, rules-of-engangement,
    documentation-governance}. md are replaced correctly by their knowledge-base/framework/rules version,
    which is not a stub.

    I think these files alredy present in the core so that duplicating them in the docs area only creates confusion.

## Further steps

- Ensure that we are in a place that the system is partially working before moving further.
- Evaluate the impact of the changes required by the concerns. Address the concerns covered by the human agent.
- If required, update the init skill to match the latest fixes.
- Update the README.md of the extension directory to accomodate info about adding/modyinging some of the
    core functionalities, matching project's needs.
- Make sure that the docs agent actually saves its outcome to the proper directories in knowledge-base/docs/
    at every step that supposes generating reports or any sturctured outcome of the agent.
