'use client';

const partners = [
  {
    name: 'TRON',
    description: 'Blockchain Platform',
    role: 'Infrastructure Partner',
  },
  {
    name: 'TronLink',
    description: 'Wallet Provider',
    role: 'Integration Partner',
  },
  {
    name: 'Trust Wallet',
    description: 'Mobile Wallet',
    role: 'Integration Partner',
  },
  {
    name: 'CertiK',
    description: 'Security Auditor',
    role: 'Security Partner',
  },
];

export default function Partners() {
  return (
    <div className="bg-gray-50 py-24 sm:py-32" id="partners">
      <div className="mx-auto max-w-7xl px-6 lg:px-8">
        <div className="mx-auto max-w-2xl lg:text-center">
          <h2 className="text-base font-semibold leading-7 text-indigo-600">Partnerships</h2>
          <p className="mt-2 text-3xl font-bold tracking-tight text-gray-900 sm:text-4xl">
            Trusted by Industry Leaders
          </p>
          <p className="mt-6 text-lg leading-8 text-gray-600">
            We collaborate with the best in the blockchain industry to ensure security, reliability, and innovation
          </p>
        </div>
        <div className="mx-auto mt-16 max-w-7xl">
          <div className="grid grid-cols-1 gap-8 sm:grid-cols-2 lg:grid-cols-4">
            {partners.map((partner) => (
              <div
                key={partner.name}
                className="relative rounded-2xl border border-gray-200 p-8 shadow-sm hover:shadow-md transition-shadow"
              >
                <div className="text-center">
                  <h3 className="text-lg font-semibold text-gray-900">{partner.name}</h3>
                  <p className="mt-2 text-sm text-gray-500">{partner.description}</p>
                  <p className="mt-4 text-xs font-medium text-indigo-600">{partner.role}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
