
// html/script.js
let isDragging = false;
let dragOffsetX = 0;
let dragOffsetY = 0;
const ui = document.getElementById('spotlight-ui');
const header = document.querySelector('#spotlight-ui .header');

window.addEventListener('message', (e) => {
    const d = e.data;
    const floodBtn = document.getElementById('floodBtn');
    const alleyBtn = document.getElementById('alleyBtn');
    const trackBtn = document.getElementById('trackBtn');

    if (d.action === 'open') ui.style.display = 'block';
    if (d.action === 'update') {
        floodBtn.classList.toggle('active', d.flood);
        alleyBtn.classList.toggle('active', d.alley);
        trackBtn.classList.toggle('active', d.track);
    }
    if (d.action === 'focus') ui.classList.toggle('focused', d.focus);
    if (d.action === 'close') {
        ui.style.display = 'none';
        ui.classList.remove('focused');
    }
});



// All Lights toggle
document.getElementById('allBtn').onclick = () => {
    fetch(`https://${GetParentResourceName()}/toggleAll`, { method: 'POST' });
};

document.getElementById('floodBtn').onclick = () => {
    fetch(`https://${GetParentResourceName()}/toggleFlood`, { method: 'POST' });
};

document.getElementById('alleyBtn').onclick = () => {
    fetch(`https://${GetParentResourceName()}/toggleAlley`, { method: 'POST' });
};

document.getElementById('trackBtn').onclick = () => {
    fetch(`https://${GetParentResourceName()}/toggleTrack`, { method: 'POST' });
};

document.getElementById('closeBtn').onclick = () => {
    fetch(`https://${GetParentResourceName()}/closeUI`, { method: 'POST' });
};

// ESC to unfocus
document.addEventListener('keydown', e => {
    if (e.key === 'Escape' && ui.classList.contains('focused')) {
        fetch(`https://${GetParentResourceName()}/escape`, { method: 'POST' });
    }
});

// Dragging logic
header.addEventListener('mousedown', e => {
    if (!ui.classList.contains('focused')) return;
    isDragging = true;
    const rect = ui.getBoundingClientRect();
    dragOffsetX = e.clientX - rect.left;
    dragOffsetY = e.clientY - rect.top;
});
document.addEventListener('mouseup', () => isDragging = false);
document.addEventListener('mousemove', e => {
    if (!isDragging) return;
    ui.style.left = `${e.clientX - dragOffsetX}px`;
    ui.style.top = `${e.clientY - dragOffsetY}px`;
});