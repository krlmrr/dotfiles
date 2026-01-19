// Fading scrollbars for editor instances
(function() {
    const scrollTimeouts = new WeakMap();
    const activeScrollables = new WeakSet();

    // Watch for VS Code adding .visible class and remove it unless actively scrolling
    const observer = new MutationObserver((mutations) => {
        mutations.forEach((mutation) => {
            if (mutation.type === 'attributes' && mutation.attributeName === 'class') {
                const el = mutation.target;
                if (el.classList.contains('scrollbar') && el.classList.contains('visible')) {
                    const scrollable = el.closest('.monaco-scrollable-element');
                    if (scrollable && !activeScrollables.has(scrollable)) {
                        el.classList.remove('visible');
                        el.classList.add('invisible');
                    }
                }
            }
        });
    });

    observer.observe(document.body, {
        attributes: true,
        subtree: true,
        attributeFilter: ['class']
    });

    // Use wheel event instead of scroll event
    document.addEventListener('wheel', (e) => {
        const scrollable = e.target.closest('.monaco-scrollable-element.editor-scrollable');
        if (!scrollable) return;

        activeScrollables.add(scrollable);

        // Show scrollbars
        scrollable.querySelectorAll('.scrollbar').forEach(sb => {
            sb.classList.remove('invisible');
            sb.classList.add('visible');
        });

        // Clear existing timeout
        const existingTimeout = scrollTimeouts.get(scrollable);
        if (existingTimeout) clearTimeout(existingTimeout);

        // Hide after scrolling stops
        const timeout = setTimeout(() => {
            activeScrollables.delete(scrollable);
            scrollable.querySelectorAll('.scrollbar').forEach(sb => {
                sb.classList.remove('visible');
                sb.classList.add('invisible');
            });
        }, 1000);

        scrollTimeouts.set(scrollable, timeout);
    }, true);
})();
