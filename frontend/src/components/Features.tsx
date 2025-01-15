'use client';

import {
  CurrencyDollarIcon,
  ShieldCheckIcon,
  BoltIcon,
  ArrowPathIcon,
} from '@heroicons/react/24/outline';

const features = [
  {
    name: 'TRC-20 Compliant',
    description: 'Fully compliant with the TRC-20 token standard on the TRON blockchain.',
    icon: ShieldCheckIcon,
  },
  {
    name: 'Fast Transactions',
    description: 'Lightning-fast transaction processing with minimal fees.',
    icon: BoltIcon,
  },
  {
    name: 'Secure',
    description: 'Built with robust security measures and audited smart contracts.',
    icon: CurrencyDollarIcon,
  },
  {
    name: 'Cross-Platform',
    description: 'Seamless integration with major wallets and exchanges.',
    icon: ArrowPathIcon,
  },
];

export default function Features() {
  return (
    <div className="bg-white py-24 sm:py-32" id="features">
      <div className="mx-auto max-w-7xl px-6 lg:px-8">
        <div className="mx-auto max-w-2xl lg:text-center">
          <h2 className="text-base font-semibold leading-7 text-indigo-600">Features</h2>
          <p className="mt-2 text-3xl font-bold tracking-tight text-gray-900 sm:text-4xl">
            Everything you need in a TRC-20 token
          </p>
          <p className="mt-6 text-lg leading-8 text-gray-600">
            FTUSDT combines security, speed, and reliability to provide a seamless token experience on the TRON network.
          </p>
        </div>
        <div className="mx-auto mt-16 max-w-2xl sm:mt-20 lg:mt-24 lg:max-w-4xl">
          <dl className="grid max-w-xl grid-cols-1 gap-x-8 gap-y-10 lg:max-w-none lg:grid-cols-2 lg:gap-y-16">
            {features.map((feature) => (
              <div key={feature.name} className="relative pl-16">
                <dt className="text-base font-semibold leading-7 text-gray-900">
                  <div className="absolute left-0 top-0 flex h-10 w-10 items-center justify-center rounded-lg bg-indigo-600">
                    <feature.icon className="h-6 w-6 text-white" aria-hidden="true" />
                  </div>
                  {feature.name}
                </dt>
                <dd className="mt-2 text-base leading-7 text-gray-600">{feature.description}</dd>
              </div>
            ))}
          </dl>
        </div>
      </div>
    </div>
  );
}
