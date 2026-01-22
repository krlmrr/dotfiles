// Fading scrollbars for editor instances
(function() {
    // Defer setup to not block initial render
    const init = () => {
        const scrollTimeouts = new WeakMap();
        const activeScrollables = new WeakSet();

        const observer = new MutationObserver((mutations) => {
            for (const mutation of mutations) {
                const el = mutation.target;
                // Fast path: skip if not a scrollbar with visible class
                if (!el.classList?.contains('scrollbar') || !el.classList.contains('visible')) continue;

                const scrollable = el.closest('.monaco-scrollable-element');
                if (scrollable && !activeScrollables.has(scrollable)) {
                    el.classList.replace('visible', 'invisible');
                }
            }
        });

        observer.observe(document.body, {
            attributes: true,
            subtree: true,
            attributeFilter: ['class']
        });

        // Show scrollbars on wheel, hide after 1s of inactivity
        document.addEventListener('wheel', (e) => {
            const scrollable = e.target.closest('.monaco-scrollable-element.editor-scrollable');
            if (!scrollable) return;

            activeScrollables.add(scrollable);

            const scrollbars = scrollable.querySelectorAll('.scrollbar');
            scrollbars.forEach(sb => sb.classList.replace('invisible', 'visible'));

            const existingTimeout = scrollTimeouts.get(scrollable);
            if (existingTimeout) clearTimeout(existingTimeout);

            scrollTimeouts.set(scrollable, setTimeout(() => {
                activeScrollables.delete(scrollable);
                scrollbars.forEach(sb => sb.classList.replace('visible', 'invisible'));
            }, 1000));
        }, { passive: true, capture: true });
    };

    // Wait for idle time to set up, don't block boot
    if (typeof requestIdleCallback !== 'undefined') {
        requestIdleCallback(init, { timeout: 2000 });
    } else {
        setTimeout(init, 100);
    }
})();
