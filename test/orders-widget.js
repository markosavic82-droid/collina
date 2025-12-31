// Orders Widget Component
window.OrdersWidget = function(props) {
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
      React.createElement('span', { key: 'icon', style: { fontSize: '24px' } }, '📦'),
      React.createElement('h2', { key: 'title', style: { fontSize: '18px', color: 'white' } }, 'Orders Widget'),
    ]),
    React.createElement('p', {
      key: 'value',
      style: { fontSize: '42px', fontWeight: 700, color: '#06B6D4' }
    }, '342'),
    React.createElement('p', {
      key: 'subtitle',
      style: { color: '#888', fontSize: '14px' }
    }, 'orders today'),
  ]);
};

// Register widget
window.WidgetRegistry = window.WidgetRegistry || {};
window.WidgetRegistry.orders = {
  id: 'orders',
  name: 'Orders',
  icon: '📦',
  component: window.OrdersWidget,
};
