'use client';

const stats = [
  { name: 'Total Supply', value: '1,000,000,000 FTUSDT' },
  { name: 'Holders', value: '10,000+' },
  { name: 'Market Cap', value: '$50M+' },
  { name: 'Transactions', value: '1M+' },
];

export default function TokenStats() {
  return (
    <div className="bg-white py-24 sm:py-32" id="token-info">
      <div className="mx-auto max-w-7xl px-6 lg:px-8">
        <div className="mx-auto max-w-2xl lg:text-center">
          <h2 className="text-base font-semibold leading-7 text-indigo-600">Token Metrics</h2>
          <p className="mt-2 text-3xl font-bold tracking-tight text-gray-900 sm:text-4xl">
            FTUSDT by the Numbers
          </p>
          <p className="mt-6 text-lg leading-8 text-gray-600">
            Track the growth and adoption of Flash USDT token across the TRON network
          </p>
        </div>
        <dl className="mt-16 grid grid-cols-1 gap-0.5 overflow-hidden rounded-2xl text-center sm:grid-cols-2 lg:grid-cols-4">
          {stats.map((stat) => (
            <div key={stat.name} className="flex flex-col bg-gray-400/5 p-8">
              <dt className="text-sm font-semibold leading-6 text-gray-600">{stat.name}</dt>
              <dd className="order-first text-3xl font-semibold tracking-tight text-gray-900">
                {stat.value}
              </dd>
            </div>
          ))}
        </dl>
      </div>
    </div>
  );
}
