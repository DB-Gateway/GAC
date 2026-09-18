(() => {
    'use strict';

    const rowSelector = '.item-row[data-item-key], tbody tr[data-item-key]';
    const sectionSelector = 'section[data-section-key]';

    /**
     * Adds presentation controls without replacing, disabling, or moving responses.
     * Call refresh() after rendering or filtering. onReveal clears active filters
     * when validation needs to show an excluded question.
     */
    function create({ container, slug, onReveal = () => {} }) {
        if (!container) throw new Error('A checklist container is required.');

        const panel = container.closest('.audit-panel, .checklist-panel') || container.parentElement;
        const storageKey = `gac.checklists.view.${slug || container.id || 'default'}`;
        let mode = 'list';
        let currentKey = null;
        let currentIndex = 0;
        let rows = [];
        let matchingRows = [];

        try {
            if (window.localStorage.getItem(storageKey) === 'step') mode = 'step';
        } catch (_) {
            // The view still works when browser storage is unavailable.
        }

        const controls = document.createElement('div');
        controls.className = 'checklist-view-controls';
        controls.innerHTML = `
            <span class="checklist-view-label">View</span>
            <div class="checklist-view-toggle" role="group" aria-label="Checklist view">
                <button type="button" data-checklist-view="list" aria-pressed="true">
                    <i class="fas fa-list" aria-hidden="true"></i> List view
                </button>
                <button type="button" data-checklist-view="step" aria-pressed="false">
                    <i class="fas fa-layer-group" aria-hidden="true"></i> Step-by-step
                </button>
            </div>`;

        const navigation = document.createElement('nav');
        navigation.className = 'checklist-step-navigation';
        navigation.setAttribute('aria-label', 'Checklist question navigation');
        navigation.hidden = true;
        navigation.innerHTML = `
            <button class="button soft" type="button" data-checklist-direction="previous">
                <i class="fas fa-arrow-left" aria-hidden="true"></i> Previous
            </button>
            <div class="checklist-step-progress">
                <span class="checklist-step-count" role="status" aria-live="polite" aria-atomic="true"></span>
                <progress value="0" max="1" aria-label="Question progress"></progress>
            </div>
            <button class="button" type="button" data-checklist-direction="next">
                Next <i class="fas fa-arrow-right" aria-hidden="true"></i>
            </button>`;

        const emptyState = document.createElement('p');
        emptyState.className = 'checklist-view-empty';
        emptyState.textContent = 'No questions match these filters. Adjust the filters to continue.';
        emptyState.setAttribute('role', 'status');
        emptyState.hidden = true;

        const controlsAnchor = panel.querySelector('#auditFilters, .column-headings') || container;
        controlsAnchor.before(controls);
        container.after(emptyState, navigation);
        container.classList.add('checklist-view-items');

        const previousButton = navigation.querySelector('[data-checklist-direction="previous"]');
        const nextButton = navigation.querySelector('[data-checklist-direction="next"]');
        const count = navigation.querySelector('.checklist-step-count');
        const progress = navigation.querySelector('progress');

        function isFilteredOut(row) {
            return row.hidden || Boolean(row.closest(sectionSelector)?.hidden);
        }

        function paint() {
            const currentRow = matchingRows[currentIndex] || null;
            panel.dataset.checklistViewMode = mode;
            rows.forEach((row) => {
                row.classList.toggle('checklist-step-hidden', mode === 'step' && row !== currentRow);
            });
            container.querySelectorAll(sectionSelector).forEach((section) => {
                section.classList.toggle(
                    'checklist-step-hidden',
                    mode === 'step' && rows.length > 0 && (!currentRow || !section.contains(currentRow)),
                );
            });
            controls.querySelectorAll('[data-checklist-view]').forEach((button) => {
                button.setAttribute('aria-pressed', String(button.dataset.checklistView === mode));
            });

            navigation.hidden = mode !== 'step' || matchingRows.length === 0;
            previousButton.disabled = currentIndex === 0;
            nextButton.disabled = currentIndex >= matchingRows.length - 1;
            const total = matchingRows.length;
            const position = currentRow ? currentIndex + 1 : 0;
            count.textContent = `Question ${position} of ${total}${total < rows.length ? ' matching filters' : ''}`;
            progress.max = Math.max(total, 1);
            progress.value = position;
            emptyState.hidden = rows.length === 0 || total > 0;
        }

        function refresh() {
            rows = [...container.querySelectorAll(rowSelector)];
            matchingRows = rows.filter((row) => !isFilteredOut(row));
            const previousIndex = matchingRows.findIndex((row) => row.dataset.itemKey === currentKey);
            currentIndex = previousIndex >= 0
                ? previousIndex
                : Math.max(0, Math.min(currentIndex, matchingRows.length - 1));
            currentKey = matchingRows[currentIndex]?.dataset.itemKey || null;

            // Keep hourly labels beside their existing cells in the compact view.
            container.querySelectorAll('.restroom-table').forEach((table) => {
                const headings = [...(table.tHead?.rows[0]?.cells || [])].map((cell) => cell.textContent.trim());
                table.querySelectorAll('tbody tr[data-item-key]').forEach((row) => {
                    [...row.cells].forEach((cell, index) => {
                        if (index > 0) cell.dataset.stepLabel = headings[index] || '';
                    });
                });
            });
            paint();
        }

        function focusQuestion(row) {
            if (!row) return;
            if (!row.hasAttribute('tabindex')) row.setAttribute('tabindex', '-1');
            row.focus({ preventScroll: true });
            const reduceMotion = window.matchMedia?.('(prefers-reduced-motion: reduce)').matches;
            row.scrollIntoView({ behavior: reduceMotion ? 'auto' : 'smooth', block: 'nearest' });
        }

        function setMode(value) {
            if (!['list', 'step'].includes(value)) return;
            mode = value;
            try {
                window.localStorage.setItem(storageKey, mode);
            } catch (_) {
                // Storage is an enhancement, never a requirement for navigation.
            }
            refresh();
        }

        function reveal(row, { focus = true } = {}) {
            if (!row || !container.contains(row) || !row.matches(rowSelector)) return false;
            if (isFilteredOut(row)) onReveal(row);
            refresh();
            const index = matchingRows.indexOf(row);
            if (index < 0) return false;
            currentIndex = index;
            currentKey = row.dataset.itemKey;
            paint();
            if (focus) focusQuestion(row);
            return true;
        }

        controls.addEventListener('click', (event) => {
            const button = event.target.closest('[data-checklist-view]');
            if (button) setMode(button.dataset.checklistView);
        });
        navigation.addEventListener('click', (event) => {
            const button = event.target.closest('[data-checklist-direction]');
            if (!button || button.disabled) return;
            const offset = button.dataset.checklistDirection === 'next' ? 1 : -1;
            currentIndex = Math.max(0, Math.min(currentIndex + offset, matchingRows.length - 1));
            currentKey = matchingRows[currentIndex]?.dataset.itemKey || null;
            paint();
            focusQuestion(matchingRows[currentIndex]);
        });

        refresh();
        return Object.freeze({ refresh, reveal, setMode, getMode: () => mode });
    }

    window.ChecklistViewMode = Object.freeze({ create });
})();
