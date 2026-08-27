/**
 * UX feature initializers.
 *
 * Each feature is independently initialized so missing markup or an error
 * in one feature does not prevent other features from running.
 */
(() => {
  "use strict";

  const root = document.documentElement;

  /*
   * Replace the fallback class when JavaScript runs.
   *
   * Without JavaScript, `.no-js` remains and the navigation uses its
   * non-interactive fallback presentation.
   */
  root.classList.remove("no-js");
  root.classList.add("js");

  /**
   * Show the back-to-top link after the page header leaves the viewport.
   */
  const initScrollButton = () => {
    const button = document.querySelector(".scroll-to-top");
    const header = document.querySelector("header");

    // Stop only this initializer when its optional markup is absent.
    if (!button) return;

    /**
     * Keep visual and interactive states synchronized.
     */
    const setButtonVisibility = (visible) => {
      const hidden = !visible;

      button.setAttribute("aria-hidden", String(hidden));
      button.toggleAttribute("inert", hidden);
    };

    // Prevent a visible flash while the initial scroll position is measured.
    setButtonVisibility(false);

    if (!header) return;

    if (typeof IntersectionObserver === "function") {
      const observer = new IntersectionObserver(
        ([entry]) => setButtonVisibility(!entry.isIntersecting),
        { threshold: 0 }
      );

      observer.observe(header);
      return;
    }

    // Provide a small fallback for browsers without IntersectionObserver.
    let scrollFrame;
    const syncButton = () => {
      scrollFrame = undefined;
      setButtonVisibility(header.getBoundingClientRect().bottom <= 0);
    };

    const handleScroll = () => {
      if (scrollFrame !== undefined) return;
      scrollFrame = requestAnimationFrame(syncButton);
    };

    window.addEventListener("scroll", handleScroll, { passive: true });
    syncButton();
  };

  /**
   * Initialize the responsive mobile navigation.
   */
  const initMobileMenu = () => {
    /*
     * Find the elements required by this feature. If one is absent, stop
     * only the mobile-menu initializer.
     */
    const menu = document.querySelector("#mainMenu");
    const openButton = document.querySelector(".mobile-menu-open");
    const closeButton = document.querySelector(".mobile-menu-close");

    if (!menu || !openButton || !closeButton) return;

    /*
     * Treat the menu as mobile when CSS displays the mobile opener.
     *
     * This makes CSS the source of truth without duplicating its breakpoint
     * or relying on a separate custom property.
     */
    const isMobileMenu = () =>
      getComputedStyle(openButton).display !== "none";

    /*
     * Identify controls that may participate in the menu's focus loop.
     */
    const focusableSelector = [
      "a[href]",
      "button:not([disabled])",
      "[tabindex]:not([tabindex='-1'])"
    ].join(",");

    /*
     * Track the previous responsive mode so resizing within the same mode
     * does not repeatedly reset an open menu.
     */
    let previousMobileMode;

    /*
     * Store the pending animation frame used to process resize events after
     * the browser has recalculated responsive styles.
     */
    let resizeFrame;

    /*
     * Preserve the original inert state of content outside the menu.
     */
    let backgroundState = new Map();

    /**
     * Set the navigation's inert state explicitly.
     *
     * `inert` is a Boolean attribute. Removing the attribute guarantees that
     * the desktop navigation becomes interactive.
     */
    const setMenuInert = (inert) => {
      menu.toggleAttribute("inert", inert);
    };

    /**
     * Find the document branches outside the navigation.
     *
     * Walk from the navigation toward the document root and collect sibling
     * branches at each level.
     */
    const getBackgroundElements = () => {
      const elements = [];
      let branch = menu;

      /*
       * Stop before the root. Making an ancestor of the menu inert would
       * disable the menu itself.
       */
      while (
        branch.parentElement &&
        branch.parentElement !== root
      ) {
        for (const sibling of branch.parentElement.children) {
          if (
            sibling !== branch &&
            sibling instanceof HTMLElement
          ) {
            elements.push(sibling);
          }
        }

        branch = branch.parentElement;
      }

      return elements;
    };

    /**
     * Enable or disable interaction with content obscured by the overlay.
     *
     * Existing inert attributes are preserved and restored accurately.
     */
    const setBackgroundInert = (inert) => {
      if (inert) {
        /*
         * Avoid overwriting the original states if the menu is already open.
         */
        if (backgroundState.size > 0) return;

        backgroundState = new Map(
          getBackgroundElements().map((element) => [
            element,
            element.hasAttribute("inert")
          ])
        );

        // Disable each background branch.
        for (const element of backgroundState.keys()) {
          element.toggleAttribute("inert", true);
        }

        return;
      }

      // Restore each branch to its original state.
      for (const [element, previousState] of backgroundState) {
        element.toggleAttribute("inert", previousState);
      }

      backgroundState.clear();
    };

    /**
     * Return only currently rendered focus targets.
     *
     * The rendered-size check excludes controls hidden by responsive CSS.
     */
    const getFocusableElements = () =>
      [...menu.querySelectorAll(focusableSelector)].filter(
        (element) => element.getClientRects().length > 0
      );

    /**
     * Open the mobile overlay.
     */
    const openMenu = () => {
      /*
       * Ignore desktop activation and repeated activation while the menu is
       * already open.
       */
      if (
        !isMobileMenu() ||
        menu.classList.contains("is-open")
      ) {
        return;
      }

      /*
       * Make the menu interactive before displaying it so the close control
       * can receive focus.
       */
      setMenuInert(false);
      menu.classList.add("is-open");
      openButton.setAttribute("aria-expanded", "true");

      // Lock scrolling and disable the obscured page.
      document.body.classList.add("menu-is-open");
      setBackgroundInert(true);

      /*
       * Wait until the open state is rendered before focusing the closer.
       */
      requestAnimationFrame(() => closeButton.focus());
    };

    /**
     * Close the mobile overlay.
     *
     * Focus normally returns to the opener. Link activation can disable that
     * behavior because navigation determines the next focus context.
     */
    const closeMenu = ({ restoreFocus = true } = {}) => {
      // Start the visual closing transition.
      menu.classList.remove("is-open");
      openButton.setAttribute("aria-expanded", "false");

      // Restore page scrolling and background access.
      document.body.classList.remove("menu-is-open");
      setBackgroundInert(false);

      /*
       * Return focus before disabling the closing menu.
       */
      if (restoreFocus && isMobileMenu()) {
        openButton.focus();
      }

      /*
       * Keep the closed menu inert only in mobile mode. This explicitly
       * removes inert whenever desktop styles display the navigation.
       */
      setMenuInert(isMobileMenu());
    };

    /**
     * Handle keyboard interaction while the overlay is open.
     */
    const handleKeydown = (event) => {
      // Ignore keyboard events while the overlay is closed.
      if (!menu.classList.contains("is-open")) return;

      // Allow Escape to dismiss the overlay.
      if (event.key === "Escape") {
        event.preventDefault();
        closeMenu();
        return;
      }

      // Only Tab requires focus-loop handling.
      if (event.key !== "Tab") return;

      const focusableElements = getFocusableElements();
      const firstElement = focusableElements[0];
      const lastElement = focusableElements.at(-1);

      // Stop if the menu has no available focus targets.
      if (!firstElement) return;

      /*
       * Recover focus if it somehow moves outside the menu.
       */
      if (!menu.contains(document.activeElement)) {
        event.preventDefault();
        firstElement.focus();
        return;
      }

      /*
       * Wrap Shift+Tab from the first control to the last control.
       */
      if (
        event.shiftKey &&
        document.activeElement === firstElement
      ) {
        event.preventDefault();
        lastElement.focus();
        return;
      }

      /*
       * Wrap Tab from the last control to the first control.
       */
      if (
        !event.shiftKey &&
        document.activeElement === lastElement
      ) {
        event.preventDefault();
        firstElement.focus();
      }
    };

    /**
     * Close the overlay after a navigation link is selected.
     */
    const handleMenuClick = (event) => {
      // Ensure the target supports `closest()`.
      if (!(event.target instanceof Element)) return;

      // Ignore clicks that did not originate from a link.
      if (!event.target.closest("a[href]")) return;

      // Desktop navigation does not use overlay behavior.
      if (!isMobileMenu()) return;

      /*
       * Do not restore opener focus because the link determines the next
       * navigation or focus context.
       */
      closeMenu({ restoreFocus: false });
    };

    /**
     * Synchronize the menu when responsive styles change mode.
     */
    const syncMenu = () => {
      const mobileMode = isMobileMenu();

      /*
       * If the page remains in desktop mode, still remove inert explicitly.
       * This repairs any stale state left by a mobile layout.
       */
      if (mobileMode === previousMobileMode) {
        if (!mobileMode) {
          setMenuInert(false);
        }

        return;
      }

      previousMobileMode = mobileMode;

      // Clear temporary overlay state.
      menu.classList.remove("is-open");
      openButton.setAttribute("aria-expanded", "false");

      // Restore the page before applying the new mode.
      document.body.classList.remove("menu-is-open");
      setBackgroundInert(false);

      /*
       * A closed mobile menu is inert. A persistent desktop menu is always
       * interactive.
       */
      setMenuInert(mobileMode);
    };

    /**
     * Process resize changes after responsive styles have been recalculated.
     *
     * The animation frame also prevents repeated synchronous work during
     * rapid resizing.
     */
    const handleResize = () => {
      cancelAnimationFrame(resizeFrame);
      resizeFrame = requestAnimationFrame(syncMenu);
    };

    // Bind controls and responsive behavior.
    openButton.addEventListener("click", openMenu);
    closeButton.addEventListener("click", () => closeMenu());
    menu.addEventListener("click", handleMenuClick);
    document.addEventListener("keydown", handleKeydown);
    window.addEventListener("resize", handleResize);

    // Establish the correct state for the initial viewport.
    syncMenu();

    /*
     * Enable menu transitions only after the synchronized closed state has
     * been rendered. This prevents initialization from looking like a
     * user-triggered close animation.
     */
    requestAnimationFrame(() => {
      requestAnimationFrame(() => root.classList.add("menu-ready"));
    });
  };

  /**
   * Initialize UX features independently.
   */
  const init = () => {
    initMobileMenu();
    initScrollButton();

    // initAccordion();
    // initTabs();
    // initOtherFeature();
  };

  init();
})();
