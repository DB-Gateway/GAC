(function () {
    'use strict';

    let instanceCount = 0;

    function create(options) {
        const container = options.container;
        if (!(container instanceof HTMLElement)) {
            throw new TypeError('ChecklistEditorSort requires a container element.');
        }
        const overlayRoot = container.closest('dialog') || document.body;

        const instructions = document.createElement('span');
        instructions.id = 'checklist-sort-instructions-' + (++instanceCount);
        instructions.className = 'editor-sort-sr-only';
        instructions.textContent = 'Drag to change the order, or use the Up and Down arrow keys. Press Escape to cancel a drag.';
        const announcement = document.createElement('span');
        announcement.className = 'editor-sort-sr-only';
        announcement.setAttribute('role', 'status');
        announcement.setAttribute('aria-live', 'polite');
        overlayRoot.append(instructions, announcement);

        let gesture = null;
        let scrollFrame = null;
        let lastFrameTime = null;
        let suppressClick = false;
        let clickReset = null;
        let destroyed = false;

        const sections = () => Array.from(container.children).filter(child => child.matches('.editor-section'));
        const itemsContainer = section => Array.from(section.children).find(child => child.matches('[data-editor-items]'));
        const items = list => Array.from(list.children).filter(child => child.matches('.editor-item'));
        const peers = element => element.matches('.editor-section') ? sections() : items(element.parentElement);

        function updateEmptyLists() {
            sections().forEach(section => {
                const list = itemsContainer(section);
                if (list) list.classList.toggle('editor-sort-empty', items(list).length === 0);
            });
        }

        function refresh() {
            if (destroyed) return;
            container.querySelectorAll('[data-editor-drag]').forEach(handle => {
                const type = handle.dataset.editorDrag;
                if (type !== 'section' && type !== 'item') return;
                handle.setAttribute('draggable', 'false');
                handle.setAttribute('aria-keyshortcuts', 'ArrowUp ArrowDown Escape');
                if (!handle.hasAttribute('aria-label')) {
                    handle.setAttribute('aria-label', type === 'section' ? 'Move section' : 'Move question');
                }
                const describedBy = new Set((handle.getAttribute('aria-describedby') || '').split(/\s+/).filter(Boolean));
                describedBy.add(instructions.id);
                handle.setAttribute('aria-describedby', Array.from(describedBy).join(' '));
            });
            updateEmptyLists();
        }

        function announce(type, element) {
            const index = peers(element).indexOf(element) + 1;
            const sectionIndex = type === 'item' ? sections().indexOf(element.closest('.editor-section')) + 1 : null;
            announcement.textContent = (type === 'section' ? 'Section' : 'Question') + ' moved to position ' + index +
                (sectionIndex ? ' in section ' + sectionIndex : '') + '.';
        }

        function notifyReorder(type, element, sourceContainer) {
            updateEmptyLists();
            announce(type, element);
            if (typeof options.onReorder === 'function') {
                options.onReorder({ type, element, sourceContainer, targetContainer: element.parentElement });
            }
        }

        function resolveHandle(target) {
            if (!(target instanceof Element)) return null;
            const handle = target.closest('[data-editor-drag]');
            if (!handle || !container.contains(handle) || handle.disabled) return null;
            const type = handle.dataset.editorDrag;
            const element = type === 'section' ? handle.closest('.editor-section') :
                type === 'item' ? handle.closest('.editor-item') : null;
            if (!element || !container.contains(element)) return null;
            if (type === 'section' && element.parentElement !== container) return null;
            if (type === 'item' && !element.parentElement.matches('[data-editor-items]')) return null;
            return { handle, type, element };
        }

        function findScrollContainer() {
            if (options.scrollContainer instanceof HTMLElement) return options.scrollContainer;
            for (let parent = container.parentElement; parent; parent = parent.parentElement) {
                if (/(auto|scroll)/.test(window.getComputedStyle(parent).overflowY)) return parent;
            }
            return document.scrollingElement || document.documentElement;
        }

        function moveBefore(element, list, next) {
            if (next === element || (element.parentElement === list && element.nextElementSibling === next)) return;
            if (!next && element.parentElement === list && element === list.lastElementChild) return;
            list.insertBefore(element, next);
            updateEmptyLists();
        }

        function reorderAtPointer() {
            const current = gesture;
            if (!current || !current.started) return;
            const bounds = container.getBoundingClientRect();
            if (current.x < bounds.left - 24 || current.x > bounds.right + 24) return;
            const hit = document.elementFromPoint(current.x, current.y);

            if (current.type === 'section') {
                if (hit && hit.closest('.editor-section') === current.element) return;
                const next = sections().filter(section => section !== current.element).find(section => {
                    const rect = section.getBoundingClientRect();
                    return current.y < rect.top + rect.height / 2;
                });
                moveBefore(current.element, container, next || null);
                return;
            }

            if (hit && hit.closest('.editor-item') === current.element) return;
            const targetSection = sections().find(section => {
                const rect = section.getBoundingClientRect();
                return current.y >= rect.top && current.y <= rect.bottom;
            });
            if (!targetSection) return;
            const targetList = itemsContainer(targetSection);
            if (!targetList) return;
            const next = items(targetList).filter(item => item !== current.element).find(item => {
                const rect = item.getBoundingClientRect();
                return current.y < rect.top + rect.height / 2;
            });
            moveBefore(current.element, targetList, next || null);
        }

        function autoScroll(timestamp) {
            const current = gesture;
            if (!current || !current.started) return;
            const scroll = current.scroll;
            const isDocument = scroll === document.scrollingElement || scroll === document.documentElement || scroll === document.body;
            const rect = isDocument ? { top: 0, bottom: window.innerHeight, left: 0, right: window.innerWidth } : scroll.getBoundingClientRect();
            const edge = Math.min(70, (rect.bottom - rect.top) / 4);
            let speed = 0;
            if (current.x >= rect.left - 24 && current.x <= rect.right + 24) {
                if (current.y < rect.top + edge) speed = -Math.min(1, (rect.top + edge - current.y) / edge);
                else if (current.y > rect.bottom - edge) speed = Math.min(1, (current.y - rect.bottom + edge) / edge);
            }
            const elapsed = lastFrameTime === null ? 16 : Math.min(32, timestamp - lastFrameTime);
            lastFrameTime = timestamp;
            if (speed) {
                const oldTop = scroll.scrollTop;
                scroll.scrollTop += speed * elapsed * 0.8;
                if (scroll.scrollTop !== oldTop) reorderAtPointer();
            }
            scrollFrame = window.requestAnimationFrame(autoScroll);
        }

        function startDrag() {
            const current = gesture;
            current.started = true;
            current.marker = document.createComment('Original checklist position');
            current.sourceContainer.insertBefore(current.marker, current.element);
            current.scroll = findScrollContainer();
            current.element.classList.add('editor-sort-active');
            current.handle.setAttribute('aria-pressed', 'true');
            container.classList.add('editor-sorting', 'editor-sorting--' + current.type);
            document.body.classList.add('editor-sort-in-progress');
            current.preview = document.createElement('div');
            current.preview.className = 'editor-sort-preview';
            current.preview.setAttribute('aria-hidden', 'true');
            current.preview.textContent = current.type === 'section' ? 'Moving section' : 'Moving question';
            overlayRoot.appendChild(current.preview);
            announcement.textContent = current.preview.textContent + '. Release to place, or press Escape to cancel.';
            lastFrameTime = null;
            scrollFrame = window.requestAnimationFrame(autoScroll);
        }

        function onPointerDown(event) {
            if (destroyed || gesture || !event.isPrimary || event.button !== 0) return;
            const resolved = resolveHandle(event.target);
            if (!resolved) return;
            event.preventDefault();
            resolved.handle.focus({ preventScroll: true });
            gesture = {
                ...resolved,
                pointerId: event.pointerId,
                originX: event.clientX,
                originY: event.clientY,
                x: event.clientX,
                y: event.clientY,
                sourceContainer: resolved.element.parentElement,
                originalIndex: peers(resolved.element).indexOf(resolved.element),
                started: false,
            };
            try { container.setPointerCapture(event.pointerId); } catch (_) { /* Window listeners also handle uncaptured pointers. */ }
        }

        function onPointerMove(event) {
            if (!gesture || event.pointerId !== gesture.pointerId) return;
            gesture.x = event.clientX;
            gesture.y = event.clientY;
            if (!gesture.started && Math.hypot(gesture.x - gesture.originX, gesture.y - gesture.originY) < 6) return;
            event.preventDefault();
            if (!gesture.started) startDrag();
            gesture.preview.style.left = Math.max(8, Math.min(gesture.x + 14, window.innerWidth - 180)) + 'px';
            gesture.preview.style.top = Math.max(8, Math.min(gesture.y + 14, window.innerHeight - 48)) + 'px';
            reorderAtPointer();
        }

        function finishDrag(cancelled) {
            const current = gesture;
            if (!current) return;
            gesture = null;
            if (scrollFrame !== null) window.cancelAnimationFrame(scrollFrame);
            scrollFrame = null;
            try { container.releasePointerCapture(current.pointerId); } catch (_) { /* Capture may already have ended. */ }
            if (!current.started) return;
            if (cancelled && current.marker.parentNode) {
                current.marker.parentNode.insertBefore(current.element, current.marker.nextSibling);
            }
            current.marker.remove();
            current.preview.remove();
            current.element.classList.remove('editor-sort-active');
            current.handle.removeAttribute('aria-pressed');
            container.classList.remove('editor-sorting', 'editor-sorting--' + current.type);
            document.body.classList.remove('editor-sort-in-progress');
            updateEmptyLists();
            suppressClick = true;
            window.clearTimeout(clickReset);
            clickReset = window.setTimeout(() => { suppressClick = false; }, 0);
            current.handle.focus({ preventScroll: true });
            if (cancelled) {
                announcement.textContent = 'Move cancelled. Original order restored.';
            } else if (current.sourceContainer !== current.element.parentElement || current.originalIndex !== peers(current.element).indexOf(current.element)) {
                notifyReorder(current.type, current.element, current.sourceContainer);
            } else {
                announcement.textContent = 'Order unchanged.';
            }
        }

        function onPointerUp(event) {
            if (gesture && event.pointerId === gesture.pointerId) finishDrag(false);
        }

        function onPointerCancel(event) {
            if (gesture && event.pointerId === gesture.pointerId) finishDrag(true);
        }

        function onKeyDown(event) {
            if (event.key === 'Escape' && gesture) {
                event.preventDefault();
                event.stopPropagation();
                finishDrag(true);
                return;
            }
            if (gesture || event.altKey || event.ctrlKey || event.metaKey || !['ArrowUp', 'ArrowDown'].includes(event.key)) return;
            const resolved = resolveHandle(event.target);
            if (!resolved) return;
            event.preventDefault();
            const { handle, type, element } = resolved;
            const source = element.parentElement;
            const siblings = peers(element);
            const index = siblings.indexOf(element);
            const direction = event.key === 'ArrowUp' ? -1 : 1;
            const neighbor = siblings[index + direction];
            if (neighbor) {
                if (direction < 0) source.insertBefore(element, neighbor);
                else source.insertBefore(neighbor, element);
            } else if (type === 'item') {
                const allSections = sections();
                const currentSectionIndex = allSections.indexOf(element.closest('.editor-section'));
                const targetSection = allSections[currentSectionIndex + direction];
                const target = targetSection && itemsContainer(targetSection);
                if (!target) return;
                target.insertBefore(element, direction < 0 ? null : target.firstElementChild);
            } else {
                return;
            }
            handle.focus({ preventScroll: true });
            handle.scrollIntoView({ block: 'nearest', inline: 'nearest' });
            notifyReorder(type, element, source);
        }

        function onClick(event) {
            if (suppressClick && resolveHandle(event.target)) {
                event.preventDefault();
                event.stopPropagation();
            }
        }

        function onWindowBlur() { finishDrag(true); }

        container.addEventListener('pointerdown', onPointerDown);
        container.addEventListener('click', onClick, true);
        window.addEventListener('pointermove', onPointerMove, { passive: false });
        window.addEventListener('pointerup', onPointerUp);
        window.addEventListener('pointercancel', onPointerCancel);
        window.addEventListener('keydown', onKeyDown, true);
        window.addEventListener('blur', onWindowBlur);
        refresh();

        return {
            refresh,
            destroy() {
                finishDrag(true);
                destroyed = true;
                window.clearTimeout(clickReset);
                container.removeEventListener('pointerdown', onPointerDown);
                container.removeEventListener('click', onClick, true);
                window.removeEventListener('pointermove', onPointerMove);
                window.removeEventListener('pointerup', onPointerUp);
                window.removeEventListener('pointercancel', onPointerCancel);
                window.removeEventListener('keydown', onKeyDown, true);
                window.removeEventListener('blur', onWindowBlur);
                container.querySelectorAll('[data-editor-drag]').forEach(handle => {
                    const describedBy = (handle.getAttribute('aria-describedby') || '').split(/\s+/).filter(id => id && id !== instructions.id);
                    if (describedBy.length) handle.setAttribute('aria-describedby', describedBy.join(' '));
                    else handle.removeAttribute('aria-describedby');
                });
                container.querySelectorAll('.editor-sort-empty').forEach(list => list.classList.remove('editor-sort-empty'));
                instructions.remove();
                announcement.remove();
            },
        };
    }

    window.ChecklistEditorSort = { create };
})();
