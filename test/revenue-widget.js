// Revenue Widget Component
window.RevenueWidget = function(props) {
  return React.createElement('div', {
    style: {
      background: '#1A1F2E',
      borderRadius: '16px',
      padding: '24px',
      border: '1px solid rgba(255,255,255,0.05)',
    }
  }, [
    React.createElement('div', {
      key: 'header',
      style: { display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '16px' }
    }, [
      React.createElement('span', { key: 'icon', style: { fontSize: '24px' } }, '💰'),
      React.createElement('h2', { key: 'title', style: { fontSize: '18px', color: 'white' } }, 'Revenue Widget'),
    ]),
    React.createElement('p', {
      key: 'value',
      style: { fontSize: '42px', fontWeight: 700, color: '#8B5CF6' }
    }, '€125,430'),
    React.createElement('p', {
      key: 'change',
      style: { color: '#22C55E', fontSize: '14px' }
    }, '+12.5% vs yesterday'),
  ]);
};

// Register widget
window.WidgetRegistry = window.WidgetRegistry || {};
window.WidgetRegistry.revenue = {
  id: 'revenue',
  name: 'Revenue',
  icon: '💰',
  component: window.RevenueWidget,
};
