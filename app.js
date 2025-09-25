// 啟動頁互動功能
(function() {
    'use strict';

    // DOM 元素
    const ctaButton = document.querySelector('.cta-button');
    const card = document.querySelector('.card');
    const logo = document.querySelector('.logo');
    const illustration = document.querySelector('.illustration');

    // 檢查是否減少動畫
    const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    // 按鈕點擊效果
    function handleButtonClick(event) {
        event.preventDefault();
        
        // 防止重複點擊
        if (ctaButton.disabled) return;
        
        // 暫時禁用按鈕
        ctaButton.disabled = true;
        
        // 添加點擊效果類別
        ctaButton.classList.add('clicked');
        
        // 觸覺回饋（如果支援）
        if (navigator.vibrate) {
            navigator.vibrate(50);
        }
        
        // 模擬載入狀態
        const originalText = ctaButton.textContent;
        ctaButton.textContent = '載入中...';
        ctaButton.setAttribute('aria-label', '正在載入，請稍候');
        
        // 1秒後導向認證頁面
        setTimeout(() => {
            // 導向登入/註冊頁面
            window.location.href = './auth.html';
        }, 1000);
    }

    // 顯示玻璃擬態成功訊息
    function showSuccessMessage() {
        const message = document.createElement('div');
        message.className = 'success-message';
        message.textContent = '✨ 準備就緒！';
        message.setAttribute('role', 'status');
        message.setAttribute('aria-live', 'polite');
        
        // 玻璃擬態樣式
        Object.assign(message.style, {
            position: 'fixed',
            top: '30px',
            left: '50%',
            transform: 'translateX(-50%) translateY(-20px)',
            background: 'rgba(255, 255, 255, 0.2)',
            backdropFilter: 'blur(16px)',
            WebkitBackdropFilter: 'blur(16px)',
            border: '1px solid rgba(255, 255, 255, 0.3)',
            color: 'white',
            padding: '16px 28px',
            borderRadius: '50px',
            fontSize: '0.95rem',
            fontWeight: '600',
            zIndex: '1000',
            opacity: '0',
            boxShadow: '0 8px 32px rgba(255, 255, 255, 0.1), inset 0 1px 0 rgba(255, 255, 255, 0.2)',
            textShadow: '0 1px 2px rgba(0, 0, 0, 0.1)',
            transition: prefersReducedMotion ? 'none' : 'all 0.4s cubic-bezier(0.25, 0.46, 0.45, 0.94)'
        });
        
        document.body.appendChild(message);
        
        // 顯示動畫
        requestAnimationFrame(() => {
            message.style.opacity = '1';
            if (!prefersReducedMotion) {
                message.style.transform = 'translateX(-50%) translateY(0)';
            }
        });
        
        // 3秒後移除
        setTimeout(() => {
            message.style.opacity = '0';
            if (!prefersReducedMotion) {
                message.style.transform = 'translateX(-50%) translateY(-20px)';
            }
            
            setTimeout(() => {
                if (message.parentNode) {
                    message.parentNode.removeChild(message);
                }
            }, 300);
        }, 3000);
    }

    // 鍵盤導航支援
    function handleKeyNavigation(event) {
        // Enter 或 Space 鍵觸發按鈕
        if (event.target === ctaButton && (event.key === 'Enter' || event.key === ' ')) {
            event.preventDefault();
            handleButtonClick(event);
        }
        
        // Escape 鍵移除焦點
        if (event.key === 'Escape') {
            document.activeElement.blur();
        }
    }

    // 增強的滑鼠進入效果
    function handleMouseEnter() {
        if (!prefersReducedMotion) {
            ctaButton.style.transform = 'translateY(-3px) scale(1.05)';
            ctaButton.style.boxShadow = '0 12px 40px rgba(255, 255, 255, 0.2), inset 0 1px 0 rgba(255, 255, 255, 0.3)';
        }
    }

    // 滑鼠離開效果
    function handleMouseLeave() {
        if (!prefersReducedMotion) {
            ctaButton.style.transform = '';
            ctaButton.style.boxShadow = '';
        }
    }

    // 卡片懸停效果
    function handleCardHover() {
        if (!prefersReducedMotion && card) {
            card.addEventListener('mouseenter', () => {
                card.style.transform = 'translateY(-4px) scale(1.02)';
            });
            card.addEventListener('mouseleave', () => {
                card.style.transform = '';
            });
        }
    }

    // 焦點管理
    function handleFocus(event) {
        // 確保焦點可見
        event.target.scrollIntoView({ 
            behavior: prefersReducedMotion ? 'auto' : 'smooth', 
            block: 'center' 
        });
    }

    // 添加點擊效果樣式
    function addClickedStyles() {
        const style = document.createElement('style');
        style.textContent = `
            .cta-button.clicked {
                transform: scale(0.95) !important;
                box-shadow: 0 2px 8px rgba(255, 142, 60, 0.3) !important;
            }
            
            @media (prefers-reduced-motion: reduce) {
                .cta-button.clicked {
                    transform: none !important;
                }
            }
        `;
        document.head.appendChild(style);
    }

    // 初始化
    function init() {
        if (!ctaButton) {
            console.warn('CTA button not found');
            return;
        }

        // 添加樣式
        addClickedStyles();

        // 事件監聽器
        ctaButton.addEventListener('click', handleButtonClick);
        ctaButton.addEventListener('mouseenter', handleMouseEnter);
        ctaButton.addEventListener('mouseleave', handleMouseLeave);
        ctaButton.addEventListener('focus', handleFocus);
        
        // 初始化卡片懸停效果
        handleCardHover();
        
        // 鍵盤事件
        document.addEventListener('keydown', handleKeyNavigation);
        
        // 為 SVG 元素添加焦點支援
        if (logo) {
            logo.setAttribute('tabindex', '0');
            logo.setAttribute('role', 'img');
            logo.addEventListener('focus', handleFocus);
        }
        
        if (illustration) {
            illustration.setAttribute('tabindex', '0');
            illustration.setAttribute('role', 'img');
            illustration.addEventListener('focus', handleFocus);
        }

        // 頁面載入完成提示
        console.log('啟動頁已載入完成');
        
        // 為螢幕閱讀器提供頁面載入通知
        const loadMessage = document.createElement('div');
        loadMessage.setAttribute('aria-live', 'polite');
        loadMessage.setAttribute('aria-atomic', 'true');
        loadMessage.style.position = 'absolute';
        loadMessage.style.left = '-10000px';
        loadMessage.textContent = '歡迎頁面已載入完成';
        document.body.appendChild(loadMessage);
        
        // 清理載入訊息
        setTimeout(() => {
            if (loadMessage.parentNode) {
                loadMessage.parentNode.removeChild(loadMessage);
            }
        }, 1000);
    }

    // 等待 DOM 載入完成
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

    // 處理動畫偏好變更
    const mediaQuery = window.matchMedia('(prefers-reduced-motion: reduce)');
    mediaQuery.addEventListener('change', function(e) {
        if (e.matches) {
            // 使用者偏好減少動畫
            document.body.style.setProperty('--transition', 'none');
        } else {
            // 恢復動畫
            document.body.style.removeProperty('--transition');
        }
    });

})();