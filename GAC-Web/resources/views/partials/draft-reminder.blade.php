@if (auth()->user()?->receivesTaskCompletionNotifications())
    <dialog class="draft-reminder-dialog" id="draftReminderModal" aria-labelledby="draftReminderTitle" aria-describedby="draftReminderDescription"
            data-drafts-url="{{ route('notifications.drafts.index') }}">
        <div class="modal-heading">
            <div>
                <h2 id="draftReminderTitle">Unfinished checklist drafts</h2>
                <p id="draftReminderDescription">Review saved progress and remind the assigned user to finish their checklist in the mobile app.</p>
            </div>
            <button type="button" class="modal-close" data-dismiss-draft-reminder aria-label="Close draft follow-up">
                <i class="fas fa-xmark" aria-hidden="true"></i>
            </button>
        </div>
        <div class="draft-reminder-body">
            <div class="draft-follow-up-toolbar">
                <span>{{ auth()->user()->hasAdministrativeAccess() ? 'All branches' : auth()->user()->branch }}</span>
                <button type="button" class="button" data-refresh-drafts>Refresh drafts</button>
            </div>
            <p data-draft-list-status role="status" aria-live="polite"></p>
            <div class="draft-reminder-list" data-draft-reminder-list></div>
        </div>
    </dialog>

    <script>
        (() => {
            const dialog = document.getElementById('draftReminderModal');
            if (!dialog || window.__gatewayDraftFollowUpInitialized) return;
            window.__gatewayDraftFollowUpInitialized = true;
            const list = dialog.querySelector('[data-draft-reminder-list]');
            const status = dialog.querySelector('[data-draft-list-status]');
            const refresh = dialog.querySelector('[data-refresh-drafts]');
            let trigger = null;
            let loading = false;

            const textElement = (tag, text, className) => {
                const element = document.createElement(tag);
                element.textContent = text;
                if (className) element.className = className;
                return element;
            };
            const formatTime = (value) => value ? new Date(value).toLocaleString() : 'Not recorded';

            const renderDraft = (draft) => {
                const card = document.createElement('article');
                card.className = 'draft-follow-up-card';
                card.dataset.userName = draft.user_name || '';
                card.dataset.userType = draft.user_type || '';
                const heading = document.createElement('div');
                heading.className = 'draft-follow-up-heading';
                heading.append(textElement('h3', draft.user_name), textElement('span', draft.user_role));
                card.append(heading, textElement('strong', `${draft.template_name} · Draft #${draft.id}`));
                card.append(textElement('p', `${draft.branch || 'Unassigned branch'} · Audit date: ${draft.audit_date}`));
                card.append(textElement('p', `${draft.answered_count} of ${draft.total_count} questions answered${draft.slot_key ? ` for ${draft.slot_key}` : ''}`, 'draft-follow-up-progress'));
                const position = document.createElement('div');
                position.className = 'draft-follow-up-position';
                position.append(textElement('strong', draft.item_number ? `${draft.position_label} #${draft.item_number}` : draft.position_label));
                if (draft.item_key) position.append(textElement('span', `${draft.item_key}${draft.section_title ? ` · ${draft.section_title}` : ''}`));
                if (draft.item_prompt) position.append(textElement('p', draft.item_prompt));
                if (draft.customer_index) position.append(textElement('span', `Customer sample ${draft.customer_index}`));
                card.append(position, textElement('small', `Last saved: ${formatTime(draft.updated_at)}`));
                const actions = document.createElement('div');
                actions.className = 'draft-follow-up-actions';
                const feedback = textElement('span', draft.last_reminded_at ? `Last reminder: ${formatTime(draft.last_reminded_at)}` : '', 'draft-follow-up-feedback');
                feedback.setAttribute('role', 'status');
                const send = textElement('button', 'Send mobile reminder', 'button primary');
                send.type = 'button';
                send.setAttribute('aria-label', `Remind ${draft.user_name} to finish ${draft.template_name}, draft ${draft.id}`);
                send.disabled = !draft.can_remind;
                if (!draft.can_remind) feedback.textContent = draft.unavailable_reason;
                send.addEventListener('click', async () => {
                    send.disabled = true;
                    refresh.disabled = true;
                    send.textContent = 'Sending…';
                    feedback.textContent = '';
                    try {
                        const response = await fetch(draft.remind_url, {
                            method: 'POST', credentials: 'same-origin',
                            headers: {
                                Accept: 'application/json', 'Content-Type': 'application/json',
                                'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]')?.content || '',
                            },
                            body: JSON.stringify({}),
                        });
                        const result = await response.json();
                        if (!response.ok) throw new Error(result.message || 'The reminder could not be sent.');
                        feedback.textContent = result.message;
                        send.textContent = 'Reminder sent';
                    } catch (error) {
                        feedback.textContent = error.message || 'The reminder could not be sent. Please try again.';
                        send.disabled = false;
                        send.textContent = 'Send mobile reminder';
                    } finally {
                        refresh.disabled = false;
                    }
                });
                actions.append(feedback, send);
                card.append(actions);
                return card;
            };

            const loadDrafts = async () => {
                if (loading) return;
                loading = true;
                refresh.disabled = true;
                status.textContent = 'Loading unfinished checklists…';
                list.replaceChildren();
                try {
                    const response = await fetch(dialog.dataset.draftsUrl, { headers: { Accept: 'application/json' }, credentials: 'same-origin', cache: 'no-store' });
                    const result = await response.json();
                    if (!response.ok) throw new Error(result.message || 'Drafts could not be loaded.');
                    const rawDrafts = result.drafts || [];
                    const seen = new Set();
                    const drafts = rawDrafts
                        .slice()
                        .sort((a, b) => new Date(b.updated_at || 0) - new Date(a.updated_at || 0))
                        .filter((draft) => {
                            const name = (draft.user_name || '').trim().toLowerCase();
                            const type = (draft.user_type || draft.user_role || '').trim().toLowerCase();
                            if (!name && !type) return true;
                            const key = `${name}|${type}`;
                            if (seen.has(key)) return false;
                            seen.add(key);
                            return true;
                        });
                    drafts.forEach((draft) => list.append(renderDraft(draft)));
                    status.textContent = drafts.length ? `${drafts.length} unfinished ${drafts.length === 1 ? 'checklist' : 'checklists'}` : 'No unfinished checklist drafts remain.';
                } catch (error) {
                    status.textContent = error.message || 'Drafts could not be loaded. Select Refresh drafts to try again.';
                } finally {
                    loading = false;
                    refresh.disabled = false;
                }
            };
            window.addEventListener('gateway:open-draft-follow-up', (event) => {
                trigger = event.detail?.trigger || document.activeElement;
                if (!dialog.open) dialog.showModal();
                void loadDrafts();
            });
            refresh.addEventListener('click', loadDrafts);
            dialog.querySelector('[data-dismiss-draft-reminder]').addEventListener('click', () => dialog.close());
            dialog.addEventListener('close', () => trigger?.focus());
            dialog.addEventListener('click', (event) => {
                if (event.target !== dialog) return;
                const bounds = dialog.getBoundingClientRect();
                if (event.clientX < bounds.left || event.clientX > bounds.right || event.clientY < bounds.top || event.clientY > bounds.bottom) dialog.close();
            });
        })();
    </script>
@endif
