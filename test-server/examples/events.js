/**
 * Event Examples for Test Environment
 *
 * These events demonstrate ticket purchasing with:
 * - EmojiShortcodes for easy sharing
 * - SVG cards with purchase spell buttons
 * - Multiple ticket types with different prices
 * - Nineum ticket flavors for blockchain integration
 */

import sessionless from 'sessionless-node';

export const events = [
  {
    id: 'event-el-popupito-001',
    uuid: sessionless.generateUUID(),
    title: 'El Popupito',
    description: 'An intimate popup dining experience featuring authentic Mexican street food with a modern twist. Chef Isabella Rodriguez brings her culinary heritage to life in this exclusive one-night event.',
    eventDate: '2025-08-15T19:00:00Z',
    location: 'Secret Location, Portland, OR (revealed upon ticket purchase)',
    type: 'popup',
    category: 'food-and-drink',
    emojiShortcode: '🌮🎪🔥🎉🍹🎭🌶️✨',
    creatorName: 'Isabella Rodriguez',
    tickets: [
      {
        type: 'General Admission',
        flavor: 'AB01CD02EF03', // ticketFlavor for nineum
        price: 7500, // $75.00 in cents
        description: 'Includes 5-course tasting menu and welcome cocktail',
        availableCount: 40
      },
      {
        type: 'VIP Experience',
        flavor: 'AB02CD03EF04', // ticketFlavor for nineum
        price: 12500, // $125.00 in cents
        description: 'Includes 7-course menu, cocktail pairings, and meet-the-chef experience',
        availableCount: 10
      }
    ],
    metadata: {
      capacity: 50,
      duration: '3 hours',
      cuisine: 'Mexican Fusion',
      dietaryOptions: ['Vegetarian', 'Gluten-Free available'],
      created_at: '2025-01-15T10:00:00Z'
    }
  },
  {
    id: 'event-starlight-concert-002',
    uuid: sessionless.generateUUID(),
    title: 'Starlight Symphony Under the Stars',
    description: 'Experience classical music like never before in this outdoor concert featuring the Portland Symphony Orchestra. Bring blankets and enjoy an evening of Beethoven, Mozart, and contemporary composers under the summer sky.',
    eventDate: '2025-07-22T20:00:00Z',
    location: 'Pioneer Courthouse Square, Portland, OR',
    type: 'concert',
    category: 'music',
    emojiShortcode: '🎵🌟🎻🌙🎶✨🎼🌌',
    creatorName: 'Portland Symphony Orchestra',
    tickets: [
      {
        type: 'Lawn Seating',
        flavor: 'CD01EF02GH03', // ticketFlavor for nineum
        price: 3500, // $35.00 in cents
        description: 'General admission lawn seating - bring your own blanket',
        availableCount: 500
      },
      {
        type: 'Premium Chair Seating',
        flavor: 'CD02EF03GH04', // ticketFlavor for nineum
        price: 6500, // $65.00 in cents
        description: 'Reserved chair seating closer to the stage',
        availableCount: 100
      },
      {
        type: 'VIP Box',
        flavor: 'CD03EF04GH05', // ticketFlavor for nineum
        price: 15000, // $150.00 in cents
        description: 'Private box for 4 people with premium seating and refreshments',
        availableCount: 20
      }
    ],
    metadata: {
      capacity: 1000,
      duration: '2.5 hours',
      genre: 'Classical',
      performers: ['Portland Symphony Orchestra', 'Guest Conductor: Maria Chen'],
      program: ['Beethoven Symphony No. 5', 'Mozart Piano Concerto No. 21', 'Contemporary works'],
      created_at: '2025-01-10T14:00:00Z'
    }
  }
];

/**
 * Generate SVG card with purchase buttons for an event
 * @param {Object} event - Event object
 * @returns {string} SVG string
 */
export function generateEventSVG(event) {
  const ticketButtons = event.tickets.map((ticket, index) => {
    const yPosition = 100 + (index * 120);
    const price = (ticket.price / 100).toFixed(2);

    return `
      <!-- ${ticket.type} Ticket Button -->
      <g spell="purchase" spell-components='{"type":"ticket","eventUUID":"${event.uuid}","eventTitle":"${event.title}","ticketFlavor":"${ticket.flavor}","price":${ticket.price},"ticketType":"${ticket.type}"}'>
        <rect x="20" y="${yPosition}" width="360" height="100" rx="12" fill="#6366f1" stroke="#4f46e5" stroke-width="3"/>
        <text x="200" y="${yPosition + 30}" text-anchor="middle" fill="white" font-size="20" font-weight="bold">
          ${ticket.type}
        </text>
        <text x="200" y="${yPosition + 55}" text-anchor="middle" fill="white" font-size="14">
          ${ticket.description}
        </text>
        <text x="200" y="${yPosition + 80}" text-anchor="middle" fill="#fbbf24" font-size="24" font-weight="bold">
          $${price}
        </text>
      </g>
    `;
  }).join('\n');

  const totalHeight = 120 + (event.tickets.length * 120);

  return `<svg width="400" height="${totalHeight}" viewBox="0 0 400 ${totalHeight}" xmlns="http://www.w3.org/2000/svg">
    <!-- Background -->
    <rect x="0" y="0" width="400" height="${totalHeight}" fill="#1e1b4b" rx="16"/>

    <!-- Event Header -->
    <text x="200" y="35" text-anchor="middle" fill="white" font-size="24" font-weight="bold">
      ${event.title}
    </text>
    <text x="200" y="60" text-anchor="middle" fill="#94a3b8" font-size="14">
      ${new Date(event.eventDate).toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' })}
    </text>
    <text x="200" y="80" text-anchor="middle" fill="#94a3b8" font-size="12">
      ${event.location}
    </text>

    ${ticketButtons}
  </svg>`;
}
