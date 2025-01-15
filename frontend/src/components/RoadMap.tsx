'use client';

import { motion } from 'framer-motion';
import { CheckCircleIcon, ClockIcon, RocketLaunchIcon } from '@heroicons/react/24/outline';

const timeline = [
  {
    name: 'Phase 1: Launch',
    description: 'Initial token launch, smart contract deployment, and security audits',
    details: [
      'Smart contract development and testing',
      'Security audit by CertiK',
      'Initial liquidity provision',
      'Community launch'
    ],
    date: 'Q1 2025',
    status: 'completed',
    icon: CheckCircleIcon,
  },
  {
    name: 'Phase 2: Growth',
    description: 'Exchange listings, partnerships, and community expansion',
    details: [
      'Major exchange listings',
      'Strategic partnerships',
      'Community rewards program',
      'Marketing campaigns'
    ],
    date: 'Q2 2025',
    status: 'current',
    icon: ClockIcon,
  },
  {
    name: 'Phase 3: Integration',
    description: 'DeFi protocols integration and cross-chain bridges',
    details: [
      'DeFi protocol partnerships',
      'Cross-chain bridge development',
      'Yield farming implementation',
      'Governance system launch'
    ],
    date: 'Q3 2025',
    status: 'upcoming',
    icon: RocketLaunchIcon,
  },
  {
    name: 'Phase 4: Ecosystem',
    description: 'Launch of Flash ecosystem products and services',
    details: [
      'Flash Pay launch',
      'Mobile app development',
      'Merchant integration tools',
      'Enterprise solutions'
    ],
    date: 'Q4 2025',
    status: 'upcoming',
    icon: RocketLaunchIcon,
  },
];

const fadeInVariants = {
  initial: { opacity: 0, y: 20 },
  animate: { opacity: 1, y: 0 },
};

export default function RoadMap() {
  return (
    <div className="bg-gradient-to-b from-white to-gray-50 py-24 sm:py-32" id="roadmap">
      <div className="mx-auto max-w-7xl px-6 lg:px-8">
        <motion.div 
          className="mx-auto max-w-2xl lg:text-center"
          initial="initial"
          whileInView="animate"
          viewport={{ once: true }}
          variants={fadeInVariants}
          transition={{ duration: 0.5 }}
        >
          <h2 className="text-base font-semibold leading-7 text-indigo-600">Roadmap</h2>
          <p className="mt-2 text-3xl font-bold tracking-tight text-gray-900 sm:text-4xl">
            Our Journey Forward
          </p>
          <p className="mt-6 text-lg leading-8 text-gray-600">
            The path to building the future of Flash USDT
          </p>
        </motion.div>

        <div className="mx-auto mt-16 max-w-7xl">
          <div className="space-y-12">
            {timeline.map((item, index) => (
              <motion.div
                key={item.name}
                className="relative"
                initial="initial"
                whileInView="animate"
                viewport={{ once: true }}
                variants={fadeInVariants}
                transition={{ duration: 0.5, delay: index * 0.2 }}
              >
                <div className="flex items-start space-x-6">
                  <div className="relative">
                    <div className={`h-12 w-12 rounded-full flex items-center justify-center border-2
                      ${item.status === 'completed' ? 'bg-green-100 border-green-500' :
                        item.status === 'current' ? 'bg-blue-100 border-blue-500' : 
                        'bg-gray-100 border-gray-300'}`}
                    >
                      <item.icon 
                        className={`h-6 w-6 
                          ${item.status === 'completed' ? 'text-green-600' :
                            item.status === 'current' ? 'text-blue-600' : 
                            'text-gray-500'}`}
                      />
                    </div>
                    {index < timeline.length - 1 && (
                      <div className="absolute left-6 top-12 h-full w-px bg-gradient-to-b from-indigo-500 to-transparent" />
                    )}
                  </div>
                  <div className="flex-1">
                    <div className="rounded-lg bg-white p-6 shadow-lg hover:shadow-xl transition-shadow duration-300">
                      <div className="flex items-center justify-between mb-4">
                        <h3 className="text-xl font-bold text-gray-900">{item.name}</h3>
                        <div className="flex items-center space-x-2">
                          <span className="text-sm font-medium text-gray-500">{item.date}</span>
                          <span className={`px-3 py-1 text-xs font-semibold rounded-full
                            ${item.status === 'completed' ? 'bg-green-100 text-green-800' :
                              item.status === 'current' ? 'bg-blue-100 text-blue-800' : 
                              'bg-gray-100 text-gray-800'}`}>
                            {item.status}
                          </span>
                        </div>
                      </div>
                      <p className="text-gray-600 mb-4">{item.description}</p>
                      <ul className="space-y-2">
                        {item.details.map((detail, idx) => (
                          <li key={idx} className="flex items-center text-sm text-gray-600">
                            <span className="mr-2">•</span>
                            {detail}
                          </li>
                        ))}
                      </ul>
                    </div>
                  </div>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
