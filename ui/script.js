// CS Casino JavaScript - Modern Interactive Interface

class CSCasino {
    constructor() {
        this.currentData = null;
        this.isOpening = false;
        this.isCollecting = false;
        this.isRegenerating = false; // Flag to prevent multiple regenerations
        this.debug = { enabled: false, ui: {} }; // Initialize debug settings
        this.init();
    }

    init() {
        this.bindEvents();
        this.setupTabNavigation();
        this.hideUI();
    }
    
    // Debug helper function
    debugLog(category, message, data = null) {
        if (!this.debug.enabled) return;
        if (!this.debug.ui[category]) return;
        
        const timestamp = new Date().toLocaleTimeString();
        const logMessage = `[${timestamp}] [CS Casino Debug/${category}] ${message}`;
        
        if (data) {
            console.log(logMessage, data);
        } else {
            console.log(logMessage);
        }
    }

    showCasePreview(caseType, caseData) {
        this.debugLog('userInteractions', 'Showing case preview for: ' + caseType);
        
        const modal = document.getElementById('case-preview-modal');
        const caseIcon = modal.querySelector('.preview-case-icon i');
        const caseName = document.getElementById('preview-case-name');
        const caseDescription = document.getElementById('preview-case-description');
        const casePrice = document.getElementById('preview-case-price');
        const itemsContainer = document.getElementById('preview-items-container');
        const totalItems = document.getElementById('preview-total-items');
        const openCaseBtn = document.getElementById('preview-open-case-btn');
        
        // Set case information
        caseIcon.className = caseData.icon || 'fas fa-box';
        caseIcon.style.color = caseData.color;
        caseName.textContent = caseData.name;
        caseDescription.textContent = caseData.description;
        casePrice.textContent = this.formatNumber(caseData.price);
        totalItems.textContent = caseData.items.length;
        
        // Calculate total weight for probability calculations
        const totalWeight = caseData.items.reduce((sum, item) => sum + item.weight, 0);
        
        // Generate items list with probabilities
        itemsContainer.innerHTML = '';
        caseData.items
            .sort((a, b) => a.weight - b.weight) // Sort by rarity (lowest weight first)
            .forEach(item => {
                const probability = ((item.weight / totalWeight) * 100).toFixed(1);
                const itemElement = this.createPreviewItem(item, probability);
                itemsContainer.appendChild(itemElement);
            });
        
        // Set up open case button
        const canAfford = this.currentData.playerMoney >= caseData.price;
        const hasLevel = this.currentData.playerData.level >= caseData.requiredLevel;
        
        if (canAfford && hasLevel && !this.isOpening) {
            openCaseBtn.disabled = false;
            openCaseBtn.onclick = () => {
                this.hideCasePreview();
                this.openCase(caseType, caseData);
            };
        } else {
            openCaseBtn.disabled = true;
            if (!canAfford) {
                openCaseBtn.innerHTML = '<i class="fas fa-coins"></i> Insufficient Funds';
            } else if (!hasLevel) {
                openCaseBtn.innerHTML = `<i class="fas fa-lock"></i> Level ${caseData.requiredLevel} Required`;
            } else if (this.isOpening) {
                openCaseBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Opening...';
            }
        }
        
        // Show modal
        modal.classList.remove('hidden');
        
        // Set up close button
        document.getElementById('preview-close-btn').onclick = () => this.hideCasePreview();
        
        // Close on background click
        modal.onclick = (e) => {
            if (e.target === modal) {
                this.hideCasePreview();
            }
        };
    }
    
    createPreviewItem(item, probability) {
        const itemElement = document.createElement('div');
        itemElement.className = 'preview-item';
        
        // Determine rarity class based on probability
        let rarityClass = 'common';
        if (probability < 1) rarityClass = 'legendary';
        else if (probability < 5) rarityClass = 'epic';
        else if (probability < 15) rarityClass = 'rare';
        else if (probability < 30) rarityClass = 'uncommon';
        
        itemElement.classList.add(rarityClass);
        
        // Format amount display
        let amountText = '';
        if (item.amount && typeof item.amount === 'object' && item.amount.min && item.amount.max) {
            amountText = `${item.amount.min}-${item.amount.max}x`;
        } else if (item.amount && item.amount > 1) {
            amountText = `${item.amount}x`;
        } else {
            amountText = '1x';
        }
        
        // Get item image from inventory system
        let itemIcon = '';
        
        // Try to get image from inventory images first
        const itemImage = this.inventoryImages[item.item];
        if (itemImage) {
            itemIcon = `<img src="${itemImage}" alt="${item.item}" class="preview-item-image">`;
        } else {
            // Check for custom mapping first
            const inventoryConfig = this.currentData.inventoryConfig;
            let imageName = item.item;
            
            if (inventoryConfig?.customMappings && inventoryConfig.customMappings[item.item]) {
                imageName = inventoryConfig.customMappings[item.item];
            } else {
                imageName = item.item + (inventoryConfig?.imageFormat || '.png');
            }
            
            // Construct primary image path
            const primaryPath = `nui://${inventoryConfig?.resourceName || 'ox_inventory'}/${inventoryConfig?.imagePath || 'web/images/'}${imageName}`;
            
            // Create fallback paths from alternative sources
            const fallbackPaths = (inventoryConfig?.alternativePaths || []).map(path => 
                `${path}${item.item}${inventoryConfig?.imageFormat || '.png'}`
            );
            
            // Create image with multiple fallback attempts
            itemIcon = this.createImageWithFallbacks(primaryPath, fallbackPaths, item.item, inventoryConfig?.fallbackIcon || 'fas fa-cube');
        }
        
        itemElement.innerHTML = `
            <div class="preview-item-icon">
                ${itemIcon}
            </div>
            <div class="preview-item-info">
                <div class="preview-item-name">${this.formatItemName(item.item)}</div>
                <div class="preview-item-amount">${amountText}</div>
            </div>
            <div class="preview-item-chance">
                <div class="chance-bar">
                    <div class="chance-fill ${rarityClass}" style="width: ${Math.min(probability * 2, 100)}%"></div>
                </div>
                <span class="chance-text">${probability}%</span>
            </div>
        `;
        
        return itemElement;
    }
    
    formatItemName(itemName) {
        // Convert item names to readable format
        return itemName
            .replace(/_/g, ' ')
            .replace(/\b\w/g, l => l.toUpperCase());
    }
    
    createImageWithFallbacks(primaryPath, fallbackPaths, itemName, fallbackIcon) {
        // Create unique identifier for this image attempt
        const imageId = `img_${itemName}_${Date.now()}`;
        
        // Build the HTML with cascading fallbacks
        let html = `<img id="${imageId}" src="${primaryPath}" alt="${itemName}" class="preview-item-image" style="display: block;"`;
        
        // Add error handler that tries fallback paths
        if (fallbackPaths && fallbackPaths.length > 0) {
            html += ` onerror="this.tryFallback = this.tryFallback || 0; `;
            
            // Add each fallback path
            fallbackPaths.forEach((path, index) => {
                html += `if (this.tryFallback === ${index}) { this.src = '${path}'; this.tryFallback++; return; } `;
            });
            
            // Final fallback to icon
            html += `if (this.tryFallback >= ${fallbackPaths.length}) { this.style.display='none'; this.nextElementSibling.style.display='flex'; }"`;
        } else {
            // No fallback paths, go straight to icon on error
            html += ` onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';"`;
        }
        
        html += `>`;
        html += `<i class="${fallbackIcon}" style="display: none; font-size: 24px; color: white;"></i>`;
        
        return html;
    }
    
    hideCasePreview() {
        const modal = document.getElementById('case-preview-modal');
        modal.classList.add('hidden');
        this.debugLog('userInteractions', 'Case preview modal closed');
    }

    forceCloseAllModals() {
        this.debugLog('functions', 'Force closing all modals');
        
        // Close case opening modal
        const caseModal = document.getElementById('case-opening-modal');
        if (caseModal) {
            caseModal.classList.add('hidden');
            caseModal.style.display = 'none';
            setTimeout(() => { caseModal.style.display = ''; }, 100);
        }
        
        // Close case preview modal
        const previewModal = document.getElementById('case-preview-modal');
        if (previewModal) {
            previewModal.classList.add('hidden');
        }
        
        // Close level up modal if exists
        const levelModal = document.querySelector('.level-up-modal');
        if (levelModal) {
            levelModal.classList.add('hidden');
        }
    }



    resetCaseOpeningUI(error) {
        this.debugLog('functions', 'Resetting case opening UI due to: ' + error);
        
        // Reset opening state completely
        this.isOpening = false;
        this.isCollecting = false;
        this.currentCaseType = null;
        this.currentCaseData = null;
        this.winningItem = null;
        this.pendingResult = null;
        
        // Force hide case opening modal immediately and ensure it's really hidden
        const modal = document.getElementById('case-opening-modal');
        if (modal) {
            modal.classList.add('hidden');
            modal.style.display = 'none';
            // Force reflow
            modal.offsetHeight;
            modal.style.display = '';
        }
        
        // Reset rolling animation completely
        const rollingItems = document.getElementById('rolling-items');
        if (rollingItems) {
            rollingItems.innerHTML = '';
            rollingItems.style.transform = 'translateX(0px)';
            rollingItems.style.animation = 'none';
            rollingItems.style.transition = 'none';
            rollingItems.classList.remove('rolling');
        }
        
        // Reset opening text
        const openingText = document.getElementById('opening-text');
        if (openingText) {
            openingText.textContent = 'Processing results...';
        }
        
        // Force hide choice buttons and item reveal
        const choiceButtons = document.getElementById('choice-buttons');
        if (choiceButtons) {
            choiceButtons.style.display = 'none';
            choiceButtons.style.opacity = '0';
            choiceButtons.style.pointerEvents = 'none';
        }
        
        const itemReveal = document.getElementById('item-reveal');
        if (itemReveal) {
            itemReveal.classList.add('hidden');
            // Remove any dynamically created choice buttons
            const dynamicButtons = itemReveal.querySelector('.choice-buttons');
            if (dynamicButtons) {
                dynamicButtons.remove();
            }
        }
        
        // Hide case preview modal if open
        const previewModal = document.getElementById('case-preview-modal');
        if (previewModal) {
            previewModal.classList.add('hidden');
        }
        
        // Reset any pending timeouts
        if (this.animationTimeout) {
            clearTimeout(this.animationTimeout);
            this.animationTimeout = null;
        }
        
        // Clear any animation intervals
        if (this.rollAnimation) {
            clearInterval(this.rollAnimation);
            this.rollAnimation = null;
        }
        
        // Force UI to return to main casino view
        const casinoContainer = document.getElementById('casino-container');
        if (casinoContainer) {
            casinoContainer.style.pointerEvents = 'auto';
        }
        
        // Re-enable case cards that aren't on cooldown
        const caseCards = document.querySelectorAll('.case-card');
        caseCards.forEach(card => {
            if (!card.classList.contains('cooldown-active')) {
                card.style.pointerEvents = 'auto';
                card.style.opacity = '1';
            }
        });
        
        this.debugLog('functions', 'Case opening UI reset completed - all states cleared and UI restored');
    }

    bindEvents() {
        // Close button
        document.getElementById('close-casino').addEventListener('click', () => {
            this.closeUI();
        });

        // ESC key to close
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && !document.getElementById('casino-container').classList.contains('hidden')) {
                this.closeUI();
            }
        });

        // Level up modal close
        document.addEventListener('click', (e) => {
            if (e.target.classList.contains('level-up-close')) {
                this.hideLevelUpModal();
            }
        });

        // NUI Message Listener
        window.addEventListener('message', (event) => {
            const { type, data } = event.data;
            this.debugLog('messages', `Received NUI message: ${type}`, data);
            
            switch (type) {
                case 'openCasino':
                    this.openCasino(data);
                    break;
                case 'caseOpened':
                    this.handleCaseOpened(data);
                    break;
                case 'cooldownStatus':
                    // For cooldownStatus, the data is directly in event.data
                    this.handleCooldownStatus(event.data);
                    break;
                case 'resetCaseOpening':
                    this.debugLog('functions', 'Received resetCaseOpening message');
                    this.forceCloseAllModals();
                    this.resetCaseOpeningUI(event.data.error || 'Reset requested');
                    break;
                case 'updateMoney':
                    this.updateMoney(data.money);
                    break;
                case 'playerStats':
                    this.displayStats(data);
                    break;
                case 'sellableItems':
                    this.displaySellableItems(data.items);
                    break;
                case 'pendingItems':
                    this.displayPendingItems(data.items);
                    break;
            }
        });
    }

    setupTabNavigation() {
        const navButtons = document.querySelectorAll('.nav-btn');
        const tabContents = document.querySelectorAll('.tab-content');

        navButtons.forEach(btn => {
            btn.addEventListener('click', () => {
                const tabId = btn.getAttribute('data-tab');
                
                // Update active nav button
                navButtons.forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
                
                // Update active tab content
                tabContents.forEach(tab => tab.classList.remove('active'));
                document.getElementById(`tab-${tabId}`).classList.add('active');
                
                // Load tab-specific data
                this.loadTabData(tabId);
            });
        });
    }

    loadTabData(tabId) {
        switch (tabId) {
            case 'inventory':
                // Load pending items only - no regular sellable items
                this.post('getPendingItems', {});
                break;
            case 'stats':
                this.post('getPlayerStats', {});
                break;
        }
    }

    openCasino(data) {
        this.currentData = data;
        this.inventoryImages = data.inventoryImages || {};
        this.branding = data.branding || {};
        this.titles = data.titles || {};
        this.debug = data.debug || { enabled: false, ui: {} }; // Update debug settings
        this.applyBranding();
        this.applyTitles();
        this.updatePlayerInfo(data.playerData, data.playerMoney);
        this.generateCases(data.cases);
        this.showUI();
    }

    closeUI() {
        this.hideUI();
        this.post('closeUI', {});
    }

    applyBranding() {
        if (!this.branding) return;
        
        // Update text content
        const logoText = document.querySelector('.logo-section h1');
        if (logoText && this.branding.name) {
            logoText.textContent = this.branding.name;
        }
        
        // Update icon
        const logoIcon = document.querySelector('.logo-section i');
        if (logoIcon && this.branding.icon) {
            logoIcon.className = this.branding.icon;
        }
        
        // Apply dynamic styling
        this.applyDynamicBrandingStyles();
    }
    
    applyTitles() {
        if (!this.titles) return;
        
        // Update page title
        const pageTitle = document.getElementById('page-title');
        if (pageTitle && this.titles.windowTitle) {
            pageTitle.textContent = this.titles.windowTitle;
        }
        
        // Update header title (if not overridden by branding)
        const headerTitle = document.querySelector('.logo-section h1');
        if (headerTitle && this.titles.headerTitle && !this.branding.name) {
            headerTitle.textContent = this.titles.headerTitle;
        }
    }
    
    applyDynamicBrandingStyles() {
        // Create or update dynamic style element
        let styleElement = document.getElementById('dynamic-branding-styles');
        if (!styleElement) {
            styleElement = document.createElement('style');
            styleElement.id = 'dynamic-branding-styles';
            document.head.appendChild(styleElement);
        }
        
        const { colors, textStyle, iconStyle } = this.branding;
        
        let css = '';
        
        // Text styling
        if (textStyle) {
            css += `
                .logo-section h1 {
                    font-family: '${textStyle.fontFamily || 'Inter'}', sans-serif !important;
                    font-size: ${textStyle.fontSize || 32}px !important;
                    font-weight: ${textStyle.fontWeight || 800} !important;
                    letter-spacing: ${textStyle.letterSpacing || 1}px !important;
                    text-transform: ${textStyle.textTransform || 'uppercase'} !important;
            `;
            
            if (colors) {
                css += `
                    background: linear-gradient(135deg, ${colors.primary || '#ffd700'}, ${colors.secondary || '#ff6b35'}, ${colors.accent1 || '#8b45c1'}, ${colors.accent2 || '#c084fc'}) !important;
                    background-size: 300% 300% !important;
                    -webkit-background-clip: text !important;
                    background-clip: text !important;
                    -webkit-text-fill-color: transparent !important;
                    text-shadow: 0 0 40px ${colors.primary || '#ffd700'}30 !important;
                `;
            }
            
            if (textStyle.animation) {
                css += `animation: gradient-shift 4s ease-in-out infinite !important;`;
            }
            
            css += `}`;
        }
        
        // Icon styling
        if (iconStyle && colors) {
            css += `
                .logo-section i {
                    font-size: ${iconStyle.size || 36}px !important;
            `;
            
            if (iconStyle.gradientIcon) {
                css += `
                    background: linear-gradient(45deg, ${colors.primary || '#ffd700'}, ${colors.secondary || '#ff6b35'}) !important;
                    background-clip: text !important;
                    -webkit-background-clip: text !important;
                    -webkit-text-fill-color: transparent !important;
                    filter: drop-shadow(0 0 25px ${colors.primary || '#ffd700'}99) !important;
                `;
            } else {
                css += `color: ${colors.primary || '#ffd700'} !important;`;
            }
            
            if (iconStyle.glowEffect) {
                css += `animation: icon-glow 3s ease-in-out infinite alternate !important;`;
            }
            
            css += `}`;
        }
        
        styleElement.textContent = css;
    }

    showUI() {
        document.getElementById('casino-container').classList.remove('hidden');
        document.body.style.overflow = 'hidden';
    }

    hideUI() {
        document.getElementById('casino-container').classList.add('hidden');
        document.body.style.overflow = 'auto';
    }

    updatePlayerInfo(playerData, money) {
        // Update basic info
        document.getElementById('player-level').textContent = playerData.level;
        document.getElementById('player-xp').textContent = playerData.experience;
        document.getElementById('player-money').textContent = this.formatNumber(money);
        
        // Calculate XP progress
        this.updateXPProgress(playerData);
    }

    updateXPProgress(playerData) {
        const level = playerData.level;
        const currentXP = playerData.experience;
        
        // Calculate XP required for current level
        let totalXPForCurrentLevel = 0;
        let totalXPForNextLevel = 1000; // Base XP for level 1
        
        for (let i = 1; i < level; i++) {
            totalXPForCurrentLevel = totalXPForNextLevel;
            totalXPForNextLevel = Math.floor(1000 * Math.pow(1.5, i));
        }
        
        if (level < 50) {
            totalXPForNextLevel = Math.floor(1000 * Math.pow(1.5, level));
        }
        
        const xpInCurrentLevel = currentXP - totalXPForCurrentLevel;
        const xpNeededForLevel = totalXPForNextLevel - totalXPForCurrentLevel;
        const progressPercent = Math.min((xpInCurrentLevel / xpNeededForLevel) * 100, 100);
        
        // Update progress bar
        document.getElementById('xp-progress').style.width = `${progressPercent}%`;
        document.getElementById('xp-current').textContent = xpInCurrentLevel;
        document.getElementById('xp-required').textContent = xpNeededForLevel;
    }

    updateMoney(newMoney) {
        document.getElementById('player-money').textContent = this.formatNumber(newMoney);
        
        // Add animation effect
        const moneyElement = document.getElementById('player-money');
        moneyElement.style.transform = 'scale(1.1)';
        moneyElement.style.color = '#c084fc';
        
        setTimeout(() => {
            moneyElement.style.transform = 'scale(1)';
            moneyElement.style.color = 'white';
        }, 300);
    }

    generateCases(cases) {
        const container = document.getElementById('cases-container');
        container.innerHTML = '';
        
        // Sort cases by required level (ascending)
        const sortedCases = Object.entries(cases).sort(([, a], [, b]) => {
            return a.requiredLevel - b.requiredLevel;
        });
        
        sortedCases.forEach(([caseType, caseData]) => {
            const caseCard = this.createCaseCard(caseType, caseData);
            container.appendChild(caseCard);
        });
    }

    createCaseCard(caseType, caseData) {
        const card = document.createElement('div');
        card.className = 'case-card';
        
        // Check if player can afford and has required level
        const canAfford = this.currentData.playerMoney >= caseData.price;
        const hasLevel = this.currentData.playerData.level >= caseData.requiredLevel;
        
        if (!canAfford || !hasLevel) {
            card.classList.add('disabled');
        }
        
        card.innerHTML = `
            <div class="case-icon" style="color: ${caseData.color}">
                <i class="${caseData.icon || 'fas fa-box'}"></i>
            </div>
            <div class="case-name">${caseData.name}</div>
            <div class="case-description">${caseData.description}</div>
            <div class="case-price">$${this.formatNumber(caseData.price)}</div>
            <div class="case-level">Level ${caseData.requiredLevel} Required</div>
            <div class="case-preview-hint">Right-click to preview contents</div>
        `;
        
        if (canAfford && hasLevel) {
            card.addEventListener('click', () => {
                if (!this.isOpening) {
                    this.openCase(caseType, caseData);
                }
            });
        }
        
        // Add right-click event for case preview
        card.addEventListener('contextmenu', (e) => {
            e.preventDefault();
            this.showCasePreview(caseType, caseData);
        });
        
        return card;
    }

    openCase(caseType, caseData) {
        if (this.isOpening) return;
        
        this.debugLog('functions', `Opening case: ${caseType}`);
        
        this.isOpening = true;
        this.currentCaseType = caseType;
        this.currentCaseData = caseData;
        
        // Show loading state
        const modal = document.getElementById('case-opening-modal');
        const openingText = document.getElementById('opening-text');
        
        modal.classList.remove('hidden');
        openingText.textContent = `Determining ${caseType} result...`;
        
        // Call server to get the actual winning item
        this.post('openCase', { caseType });
    }

    // Handle cooldown status updates from client
    handleCooldownStatus(data) {
        this.debugLog('functions', 'Received cooldown status update', data);
        
        // Safely extract data with fallbacks
        if (!data) {
            this.debugLog('functions', 'Warning: cooldown status data is undefined');
            return;
        }
        
        const isOnCooldown = data.isOnCooldown || false;
        const remainingTime = data.remainingTime || 0;
        
        // Update all case cards based on cooldown status
        this.updateCaseCardsForCooldown(isOnCooldown, remainingTime);
    }

    // Update case cards to show/hide cooldown state
    updateCaseCardsForCooldown(isOnCooldown, remainingTime) {
        const caseCards = document.querySelectorAll('.case-card');
        
        caseCards.forEach(card => {
            if (isOnCooldown) {
                // Instead of disabling, add click handler that shows cooldown message
                card.classList.add('cooldown-active');
                card.style.opacity = '0.7';
                card.style.cursor = 'not-allowed';
                
                // Remove existing click handlers
                const newCard = card.cloneNode(true);
                card.parentNode.replaceChild(newCard, card);
                
                // Add cooldown click handler
                newCard.addEventListener('click', (e) => {
                    e.preventDefault();
                    e.stopPropagation();
                    // Ask client to show cooldown notification
                    this.post('showCooldownNotification', { remainingTime });
                });
                
                // Add cooldown overlay
                let overlay = newCard.querySelector('.cooldown-overlay');
                if (!overlay) {
                    overlay = document.createElement('div');
                    overlay.className = 'cooldown-overlay';
                    newCard.appendChild(overlay);
                }
                overlay.innerHTML = `
                    <div class="cooldown-text">
                        <i class="fas fa-clock"></i>
                        <div>On Cooldown</div>
                        <div class="cooldown-time">${remainingTime}s</div>
                    </div>
                `;
            } else {
                // Enable case card - simply remove cooldown styling and regenerate all cards
                card.classList.remove('cooldown-active');
                card.style.opacity = '1';
                card.style.cursor = 'pointer';
                
                // Remove cooldown overlay
                const overlay = card.querySelector('.cooldown-overlay');
                if (overlay) {
                    overlay.remove();
                }
            }
        });
        
        // After processing all cards, regenerate them completely to restore functionality
        if (!isOnCooldown) {
            this.debugLog('functions', 'Cooldown expired - regenerating all case cards');
            // Only regenerate once by using a flag
            if (!this.isRegenerating) {
                this.isRegenerating = true;
                setTimeout(() => {
                    this.refreshCaseCards();
                    this.isRegenerating = false;
                }, 100);
            }
        }
    }

    // Helper function to find case data by case name
    findCaseDataByName(caseName) {
        if (!this.currentData || !this.currentData.cases) {
            this.debugLog('functions', 'No currentData or cases available');
            return null;
        }
        
        this.debugLog('functions', 'Looking for case: "' + caseName + '"');
        this.debugLog('functions', 'Available cases: ' + Object.keys(this.currentData.cases).join(', '));
        
        for (const [caseType, caseData] of Object.entries(this.currentData.cases)) {
            this.debugLog('functions', 'Checking case: "' + caseData.name + '" against "' + caseName + '"');
            if (caseData.name === caseName) {
                this.debugLog('functions', 'Found match for case type: ' + caseType);
                return { ...caseData, type: caseType };
            }
        }
        
        this.debugLog('functions', 'No match found for case name: ' + caseName);
        return null;
    }

    // Helper function to refresh case cards
    refreshCaseCards() {
        if (this.currentData && this.currentData.cases) {
            this.generateCases(this.currentData.cases);
        }
    }

    showCaseOpeningAnimation(caseType, caseData) {
        // This is the old function - replaced by showCaseOpeningAnimationWithResult
        this.debugLog('functions', 'Old animation function called - should not be used');
    }

    showCaseOpeningAnimationWithResult(caseType, caseData, winningItem) {
        const openingText = document.getElementById('opening-text');
        const rollingItems = document.getElementById('rolling-items');
        
        // Reset any existing animation
        rollingItems.classList.remove('rolling');
        rollingItems.style.transform = '';
        rollingItems.style.animation = '';
        
        // Generate rolling items with the actual winning item pre-placed
        this.generateRollingItemsWithWinner(caseData, winningItem);
        
        // Update opening text
        openingText.textContent = `Opening ${caseType}...`;
        
        // Force DOM reflow to ensure items are rendered first
        rollingItems.offsetHeight;
        
        // Start the rolling animation with inline styles (more reliable than CSS class)
        rollingItems.style.animation = 'roll-items 4s cubic-bezier(0.25, 0.46, 0.45, 0.94) forwards';
        
        // Update text during animation
        setTimeout(() => {
            openingText.textContent = `Processing results...`;
        }, 3000);
    }

    generateRollingItems(caseData) {
        // Old function - replaced by generateRollingItemsWithWinner
        this.debugLog('functions', 'Old generate function called - should not be used');
    }

    generateRollingItemsWithWinner(caseData, winningItem) {
        const rollingItems = document.getElementById('rolling-items');
        rollingItems.innerHTML = '';
        
        // Create 35 items for smooth rolling effect
        const totalItems = 35;
        const winningPosition = 20; // Position where the center line will stop (0-indexed)
        
        for (let i = 0; i < totalItems; i++) {
            const item = document.createElement('div');
            item.className = 'rolling-item';
            
            // If this is the winning position, use the actual winning item
            if (i === winningPosition) {
                item.classList.add('winning-item');
                const itemContent = this.generateItemContent(winningItem.name, winningItem.amount);
                item.innerHTML = itemContent;
            } else {
                // Use random items from the case for visual effect
                const randomItem = this.getRandomItemFromCase(caseData);
                const itemContent = this.generateItemContent(randomItem.name, randomItem.amount);
                item.innerHTML = itemContent;
            }
            
            rollingItems.appendChild(item);
        }
        

    }

    generateItemContent(itemName, amount) {
        if (this.inventoryImages && this.inventoryImages.enabled) {
            const imagePath = `nui://${this.inventoryImages.resourceName}/${this.inventoryImages.imagePath}${itemName}${this.inventoryImages.imageFormat}`;
            return `
                <img class="item-image" src="${imagePath}" alt="${itemName}" 
                     onerror="this.style.display='none'; this.nextElementSibling.style.display='block';">
                <div class="item-icon" style="display: none;">
                    <i class="${this.inventoryImages.fallbackIcon}"></i>
                </div>
                <div class="item-name">${this.formatItemName(itemName)}</div>
                <div class="item-amount">x${amount}</div>
            `;
        } else {
            return `
                <div class="item-icon">
                    <i class="fas fa-cube"></i>
                </div>
                <div class="item-name">${this.formatItemName(itemName)}</div>
                <div class="item-amount">x${amount}</div>
            `;
        }
    }

    formatItemName(itemName) {
        // Convert item names to more readable format
        return itemName.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
    }

    getRandomItemFromCase(caseData) {
        // Calculate total weight
        let totalWeight = 0;
        caseData.items.forEach(item => {
            totalWeight += item.weight;
        });
        
        // Get random weighted item
        const randomWeight = Math.random() * totalWeight;
        let currentWeight = 0;
        
        for (const item of caseData.items) {
            currentWeight += item.weight;
            if (randomWeight <= currentWeight) {
                return {
                    name: item.item,
                    amount: Math.floor(Math.random() * (item.max - item.min + 1)) + item.min
                };
            }
        }
        
        // Fallback
        return {
            name: caseData.items[0].item,
            amount: caseData.items[0].min
        };
    }



    handleCaseOpened(result) {
        // Clear timeout since we got a response
        if (this.animationTimeout) {
            clearTimeout(this.animationTimeout);
            this.animationTimeout = null;
        }
        
        if (result.success) {
            // Store the winning item result (but don't give it to player yet)
            this.winningItem = {
                name: result.item,
                amount: result.amount,
                label: result.itemLabel,
                sellValue: result.sellValue,
                caseType: this.currentCaseType
            };
            
            // Store the case opening result for later use
            this.pendingResult = result;
            
            // Now start the animation with the correct winning item
            this.showCaseOpeningAnimationWithResult(this.currentCaseType, this.currentCaseData, this.winningItem);
            
            // Show Keep/Sell choice after animation completes
            setTimeout(() => {
                this.showKeepSellChoice(this.winningItem);
            }, 300); // Wait for rolling animation to complete (4s + 100ms buffer)
            
        } else {
            this.hideCaseOpeningModal();
            this.isOpening = false;
        }
    }

    showKeepSellChoice(winningItem) {
        const itemReveal = document.getElementById('item-reveal');
        const itemName = document.getElementById('revealed-item-name');
        const itemAmount = document.getElementById('revealed-item-amount');
        const itemIcon = itemReveal.querySelector('.item-icon');
        
        // Show the won item
        if (this.inventoryImages && this.inventoryImages.enabled) {
            const imagePath = `nui://${this.inventoryImages.resourceName}/${this.inventoryImages.imagePath}${winningItem.name}${this.inventoryImages.imageFormat}`;
            const img = document.createElement('img');
            img.src = imagePath;
            img.alt = winningItem.label || winningItem.name;
            img.className = 'item-image';
            img.style.width = '48px';
            img.style.height = '48px';
            
            itemIcon.innerHTML = '';
            itemIcon.appendChild(img);
            
            img.onerror = () => {
                itemIcon.innerHTML = `<i class="${this.inventoryImages.fallbackIcon}"></i>`;
            };
        } else {
            itemIcon.innerHTML = '<i class="fas fa-gift"></i>';
        }
        
        itemName.textContent = winningItem.label || this.formatItemName(winningItem.name);
        itemAmount.textContent = `x${winningItem.amount}`;
        
        // Create single button to proceed
        const buttonsContainer = document.createElement('div');
        buttonsContainer.className = 'choice-buttons';
        buttonsContainer.style.opacity = '0'; // Start invisible
        buttonsContainer.style.pointerEvents = 'none'; // Disable clicks initially
        buttonsContainer.style.transform = 'translateY(20px)'; // Start slightly below
        buttonsContainer.innerHTML = `
            <button class="choice-btn keep-btn" id="collect-btn">
                <i class="fas fa-check"></i>
                ${this.titles.caseOpening?.collectButton || 'Collect Item'}
            </button>
        `;
        
        // Add buttons to item reveal
        itemReveal.appendChild(buttonsContainer);
        itemReveal.classList.remove('hidden');
        
        // Add click handler
        document.getElementById('collect-btn').addEventListener('click', () => this.collectItem());
        
        // Show button with animation after a short delay
        setTimeout(() => {
            buttonsContainer.style.transition = 'opacity 0.2s ease, transform 0.2s ease';
            buttonsContainer.style.opacity = '1';
            buttonsContainer.style.pointerEvents = 'auto';
            buttonsContainer.style.transform = 'translateY(0)';
        }, 100); // Reduced delay for faster appearance
    }

    collectItem() {
        // Prevent multiple clicks
        if (this.isCollecting) return;
        this.isCollecting = true;
        
        // Disable the collect button
        const collectBtn = document.getElementById('collect-btn');
        if (collectBtn) {
            collectBtn.disabled = true;
            collectBtn.innerHTML = `<i class="fas fa-spinner fa-spin"></i> ${this.titles.caseOpening?.collecting || 'Collecting...'}`;
        }
        
        // Add item to the pending items (shown in Sell Items tab)
        this.post('collectItem', { 
            caseType: this.winningItem.caseType,
            item: this.winningItem.name,
            amount: this.winningItem.amount,
            sellValue: this.winningItem.sellValue,
            itemLabel: this.winningItem.label
        });
        
        this.finalizeCaseOpening();
    }

    switchTab(tabName) {
        // Remove active class from all tabs
        document.querySelectorAll('.nav-btn').forEach(tab => {
            tab.classList.remove('active');
        });
        
        document.querySelectorAll('.tab-content').forEach(content => {
            content.classList.remove('active');
        });
        
        // Add active class to selected tab
        const tabBtn = document.querySelector(`[data-tab="${tabName}"]`);
        const tabContent = document.getElementById(`tab-${tabName}`);
        
        if (tabBtn && tabContent) {
            tabBtn.classList.add('active');
            tabContent.classList.add('active');
        }
        
        // Refresh content based on tab
        if (tabName === 'inventory') {
            this.post('getPendingItems');
        }
    }

    finalizeCaseOpening() {
        // Hide modal and update UI
        setTimeout(() => {
            this.hideCaseOpeningModal();
            this.isOpening = false;
            this.isCollecting = false; // Reset collecting flag
            
            // Show level up if applicable
            if (this.pendingResult.levelData && this.pendingResult.levelData.newLevel > this.pendingResult.levelData.oldLevel) {
                this.showLevelUpModal(this.pendingResult.levelData.newLevel);
            }
            
            // Update player data (money will be updated by server response)
            this.updatePlayerInfo(this.pendingResult.newPlayerData, this.currentData.playerMoney - this.getCasePrice(this.winningItem.caseType));
            
            // Refresh cases display
            this.generateCases(this.currentData.cases);
            
        }, 500);
    }

    showItemReveal(result) {
        const itemReveal = document.getElementById('item-reveal');
        const itemName = document.getElementById('revealed-item-name');
        const itemAmount = document.getElementById('revealed-item-amount');
        const itemIcon = itemReveal.querySelector('.item-icon');
        
        // Update item reveal with image if available
        if (this.inventoryImages && this.inventoryImages.enabled) {
            const imagePath = `nui://${this.inventoryImages.resourceName}/${this.inventoryImages.imagePath}${result.item}${this.inventoryImages.imageFormat}`;
            
            // Check if there's already an image, if not create one
            let itemImage = itemReveal.querySelector('.item-image-large');
            if (!itemImage) {
                itemImage = document.createElement('img');
                itemImage.className = 'item-image-large';
                itemImage.style.width = '64px';
                itemImage.style.height = '64px';
                itemImage.style.objectFit = 'contain';
                itemImage.style.marginBottom = '15px';
                itemImage.style.borderRadius = '8px';
                itemIcon.parentNode.insertBefore(itemImage, itemIcon);
            }
            
            itemImage.src = imagePath;
            itemImage.onerror = function() {
                this.style.display = 'none';
                itemIcon.style.display = 'block';
            };
            itemImage.onload = function() {
                itemIcon.style.display = 'none';
            };
        }
        
        itemName.textContent = result.itemLabel || this.formatItemName(result.item);
        itemAmount.textContent = `x${result.amount}`;
        
        itemReveal.classList.remove('hidden');
    }

    hideCaseOpeningModal() {
        const modal = document.getElementById('case-opening-modal');
        const itemReveal = document.getElementById('item-reveal');
        const rollingItems = document.getElementById('rolling-items');
        
        modal.classList.add('hidden');
        itemReveal.classList.add('hidden');
        
        // Reset the rolling animation
        rollingItems.classList.remove('rolling');
        rollingItems.innerHTML = '';
        
        // Remove choice buttons if they exist
        const choiceButtons = itemReveal.querySelector('.choice-buttons');
        if (choiceButtons) {
            choiceButtons.remove();
        }
    }

    showLevelUpModal(newLevel) {
        const modal = document.getElementById('level-up-modal');
        const levelSpan = document.getElementById('new-level');
        
        levelSpan.textContent = newLevel;
        modal.classList.remove('hidden');
    }

    hideLevelUpModal() {
        const modal = document.getElementById('level-up-modal');
        modal.classList.add('hidden');
    }

    displaySellableItems(items) {
        // This function is no longer used for the Case Items tab
        // Keep it for potential future use if needed
        this.debugLog('functions', 'displaySellableItems called but ignored for Case Items tab');
    }

    displayPendingItems(items) {
        this.debugLog('dataDisplay', 'displayPendingItems called', items);
        const container = document.getElementById('inventory-container');
        
        // Clear the container first
        container.innerHTML = '';
        
        // Always add the section header
        const headerDiv = document.createElement('div');
        headerDiv.style.gridColumn = '1 / -1';
        headerDiv.style.textAlign = 'center';
        headerDiv.style.marginBottom = '20px';
        headerDiv.innerHTML = `
            <h3 style="color: #c084fc; margin-bottom: 10px;">
                <i class="fas fa-gift"></i> Items Won from Cases
            </h3>
            <p style="color: rgba(255, 255, 255, 0.7); font-size: 14px;">
                Choose to keep items in your inventory or sell them for money (+3% bonus)
            </p>
        `;
        container.appendChild(headerDiv);
        
        // Check if there are items to display
        if (items && items.length > 0) {
            // Add pending items
            items.forEach(item => {
                const itemCard = this.createPendingItem(item);
                container.appendChild(itemCard);
                
                // Add event listeners for the buttons
                const keepBtn = itemCard.querySelector('.keep-pending-btn');
                const sellBtn = itemCard.querySelector('.sell-pending-btn');
                
                if (keepBtn) {
                    keepBtn.addEventListener('click', (e) => {
                        const itemId = e.target.closest('button').dataset.itemId;
                        this.keepPendingItem(itemId, e.target.closest('button'));
                    });
                }
                
                if (sellBtn) {
                    sellBtn.addEventListener('click', (e) => {
                        const itemId = e.target.closest('button').dataset.itemId;
                        this.sellPendingItem(itemId, e.target.closest('button'));
                    });
                }
            });
        } else {
            // Show no pending items message
            const emptyDiv = document.createElement('div');
            emptyDiv.style.gridColumn = '1 / -1';
            emptyDiv.style.textAlign = 'center';
            emptyDiv.style.padding = '40px';
            emptyDiv.style.color = 'rgba(255, 255, 255, 0.7)';
            emptyDiv.innerHTML = `
                <i class="fas fa-box-open" style="font-size: 48px; margin-bottom: 15px; opacity: 0.5;"></i>
                <p>No pending items from cases</p>
                <p style="font-size: 14px; margin-top: 10px;">Open cases to collect items here!</p>
            `;
            container.appendChild(emptyDiv);
        }
    }

    createPendingItem(item) {
        const card = document.createElement('div');
        card.className = 'inventory-item pending-item';
        
        // Generate item content with image support
        let itemIconHtml = '<i class="fas fa-gift"></i>';
        if (this.inventoryImages && this.inventoryImages.enabled) {
            const imagePath = `nui://${this.inventoryImages.resourceName}/${this.inventoryImages.imagePath}${item.name}${this.inventoryImages.imageFormat}`;
            itemIconHtml = `<img src="${imagePath}" alt="${item.label}" class="item-image" style="width: 32px; height: 32px;" onerror="this.style.display='none'; this.nextElementSibling.style.display='inline';"><i class="${this.inventoryImages.fallbackIcon}" style="display: none;"></i>`;
        }
        
        card.innerHTML = `
            <div class="item-icon">
                ${itemIconHtml}
            </div>
            <div class="item-name">${item.label || item.name}</div>
            <div class="item-count">Won: x${item.amount}</div>
            <div class="item-actions">
                <button class="sell-btn keep-pending-btn" data-item-id="${item.id}">
                    <i class="fas fa-check"></i> ${this.titles.inventory?.keepButton || 'Keep'}
                </button>
                <button class="sell-btn sell-pending-btn" data-item-id="${item.id}">
                    <i class="fas fa-dollar-sign"></i> ${this.titles.inventory?.sellButton || 'Sell'} $${item.sellValue}
                </button>
            </div>
        `;
        
        return card;
    }

    keepPendingItem(itemId, button) {
        // Disable the button to prevent multiple clicks
        if (!button) return;
        const originalText = button.innerHTML;
        button.disabled = true;
        button.innerHTML = `<i class="fas fa-spinner fa-spin"></i> ${this.titles.inventory?.keeping || 'Keeping...'}`;
        
        this.post('keepPendingItem', { itemId });
        
        // Refresh pending items after a short delay
        setTimeout(() => {
            this.post('getPendingItems', {});
        }, 300);
    }

    sellPendingItem(itemId, button) {
        // Disable the button to prevent multiple clicks
        if (!button) return;
        const originalText = button.innerHTML;
        button.disabled = true;
        button.innerHTML = `<i class="fas fa-spinner fa-spin"></i> ${this.titles.inventory?.selling || 'Selling...'}`;
        
        this.post('sellPendingItem', { itemId });
        
        // Refresh pending items after a short delay
        setTimeout(() => {
            this.post('getPendingItems', {});
        }, 300);
    }

    createInventoryItem(item) {
        const card = document.createElement('div');
        card.className = 'inventory-item';
        
        card.innerHTML = `
            <div class="item-icon">
                <i class="fas fa-cube"></i>
            </div>
            <div class="item-name">${item.label}</div>
            <div class="item-count">Owned: ${item.count}</div>
            <div class="item-sell-price">Sell for: $${this.formatNumber(item.sellValue)}</div>
            <button class="sell-btn" onclick="casino.sellItem('${item.name}', ${item.count})">
                ${this.titles.inventory?.sellAllButton || 'Sell All'} (+${item.margin}%)
            </button>
        `;
        
        return card;
    }

    sellItem(itemName, amount) {
        // Disable the button to prevent multiple clicks
        const button = event.target;
        const originalText = button.innerHTML;
        button.disabled = true;
        button.innerHTML = `<i class="fas fa-spinner fa-spin"></i> ${this.titles.inventory?.selling || 'Selling...'}`;
        
        this.post('sellItem', { itemName, amount });
        
        // Refresh sellable items after a short delay
        setTimeout(() => {
            this.post('getSellableItems', {});
            // Re-enable button in case of issues
            button.disabled = false;
            button.innerHTML = originalText;
        }, 500);
    }

    displayStats(data) {
        const { player, recentHistory } = data;
        
        // Update stats
        document.getElementById('total-cases').textContent = this.formatNumber(player.cases_opened);
        document.getElementById('total-spent').textContent = '$' + this.formatNumber(player.total_spent);
        document.getElementById('current-level').textContent = player.level;
        
        // Update history
        const historyContainer = document.getElementById('history-container');
        historyContainer.innerHTML = '';
        
        if (recentHistory.length === 0) {
            historyContainer.innerHTML = `
                <div style="text-align: center; padding: 20px; color: rgba(255, 255, 255, 0.7);">
                    <p>No recent activity</p>
                </div>
            `;
            return;
        }
        
        recentHistory.forEach(record => {
            const historyItem = document.createElement('div');
            historyItem.className = 'history-item';
            
            const date = new Date(record.created_at).toLocaleDateString();
            
            historyItem.innerHTML = `
                <div class="history-item-info">
                    <div class="history-item-name">${record.item_won} x${record.item_amount}</div>
                    <div class="history-item-details">From ${record.case_type} • ${date}</div>
                </div>
                <div class="history-item-value">$${this.formatNumber(record.case_price)}</div>
            `;
            
            historyContainer.appendChild(historyItem);
        });
    }

    getCasePrice(caseType) {
        return this.currentData.cases[caseType]?.price || 0;
    }

    formatNumber(num) {
        return new Intl.NumberFormat('en-US').format(num);
    }

    post(callback, data) {
        fetch(`https://${GetParentResourceName()}/${callback}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(data),
        }).catch(error => {
            this.debugLog('functions', `Failed to post ${callback}:`, error);
            // Don't throw - just log the error
        });
    }
}

// Initialize casino when page loads
let casino;
document.addEventListener('DOMContentLoaded', () => {
    casino = new CSCasino();
});

// Expose casino to global scope for button callbacks
window.casino = casino;
