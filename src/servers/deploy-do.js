#!/usr/bin/env node

const { createApiClient } = require('dots-wrapper');
const { NodeSSH } = require('node-ssh');
const fs = require('fs');
const path = require('path');
const { configureOwner } = require('./configure-owner');

// Load API token from gitignored file
const tokenPath = path.join(__dirname, 'do-token.json');
const { token } = JSON.parse(fs.readFileSync(tokenPath, 'utf8'));

const api = createApiClient({ token });
const ssh = new NodeSSH();

async function getAllSSHKeys() {
  try {
    const response = await api.sshKey.listSshKeys({ page: 1, per_page: 100 });
    const keys = response.data?.ssh_keys || response.ssh_keys || [];
    return keys.map(key => key.id);
  } catch (error) {
    if (error.response?.status === 403) {
      console.warn('⚠️  API token does not have permission to read SSH keys');
      console.warn('⚠️  Your token needs "read" scope for SSH keys');
      console.warn('⚠️  Create a new token at: https://cloud.digitalocean.com/account/api/tokens');
      console.warn('⚠️  Make sure to check "Read" and "Write" scopes when creating the token');
    } else {
      console.warn('⚠️  Could not fetch SSH keys:', error.message);
    }
    console.warn('Droplet will be created without SSH keys - password will be emailed');
    return [];
  }
}

async function listProjects() {
  try {
    const response = await api.project.listProjects({});
    return response.data?.projects || response.projects || [];
  } catch (error) {
    console.warn('⚠️  Could not fetch projects:', error.message);
    return [];
  }
}

async function selectProject(projectName) {
  if (!projectName) return null;

  const projects = await listProjects();

  if (projects.length === 0) {
    console.warn('⚠️  No projects found in your account');
    return null;
  }

  const project = projects.find(p =>
    p.name.toLowerCase() === projectName.toLowerCase() ||
    p.id === projectName
  );

  if (!project) {
    console.log('\n📂 Available projects:');
    projects.forEach(p => console.log(`  - ${p.name} (${p.id})`));
    throw new Error(`Project "${projectName}" not found`);
  }

  return project;
}

async function assignDropletToProject(dropletId, projectId) {
  try {
    const urn = `do:droplet:${dropletId}`;
    await api.project.assignResourcesToProject({
      project_id: projectId,
      resources: [urn]
    });
    return true;
  } catch (error) {
    console.warn('⚠️  Could not assign droplet to project:', error.message);
    return false;
  }
}

async function createDNSRecord(domain, subdomain, ip) {
  try {
    // Extract root domain (e.g., "allyabase.com" from "foo.allyabase.com")
    const parts = domain.split('.');
    const rootDomain = parts.length > 2 ? parts.slice(-2).join('.') : domain;
    const recordName = parts.length > 2 ? parts.slice(0, -2).join('.') : '@';

    console.log(`\n🌐 Creating DNS A record for ${domain}...`);
    console.log(`   Root domain: ${rootDomain}`);
    console.log(`   Record name: ${recordName}`);
    console.log(`   Points to: ${ip}`);

    const response = await api.domain.createDomainRecord({
      domain_name: rootDomain,
      type: 'A',
      name: recordName,
      data: ip,
      ttl: 3600
    });

    console.log('✅ DNS record created successfully!');
    console.log('⏳ DNS propagation may take 5-30 minutes');
    return true;
  } catch (error) {
    console.warn('\n⚠️  Could not create DNS record automatically:', error.message);

    if (error.response?.status === 422) {
      console.warn('');
      console.warn('Possible reasons:');
      console.warn(`  1. Domain "${rootDomain}" is not managed by Digital Ocean`);
      console.warn(`  2. Record "${recordName}" already exists`);
      console.warn(`  3. Domain is not properly configured`);
      console.warn('');
      console.warn('To add the domain to Digital Ocean:');
      console.warn('  1. Go to: https://cloud.digitalocean.com/networking/domains');
      console.warn('  2. Click "Add Domain"');
      console.warn(`  3. Enter: ${rootDomain}`);
      console.warn('  4. Update your domain registrar nameservers to:');
      console.warn('     - ns1.digitalocean.com');
      console.warn('     - ns2.digitalocean.com');
      console.warn('     - ns3.digitalocean.com');
    }

    console.warn('');
    console.warn('Manual DNS Setup:');
    console.warn(`  Type: A`);
    console.warn(`  Name: ${recordName}`);
    console.warn(`  Data: ${ip}`);
    console.warn(`  TTL: 3600`);
    return false;
  }
}

async function waitForDropletReady(dropletId, maxAttempts = 60) {
  console.log('Waiting for droplet to be ready...');

  for (let i = 0; i < maxAttempts; i++) {
    const response = await api.droplet.getDroplet({ droplet_id: dropletId });
    const droplet = response.data?.droplet || response.droplet;

    // Wait for status to be "active"
    if (droplet.status === 'active') {
      const networks = droplet.networks?.v4;
      if (networks && networks.length > 0) {
        const publicIP = networks.find(net => net.type === 'public');
        if (publicIP) {
          console.log(`✅ Droplet is active with IP: ${publicIP.ip_address}`);
          // Give it a few more seconds for SSH to fully initialize
          console.log('⏳ Waiting 30 seconds for SSH daemon to start...');
          await new Promise(resolve => setTimeout(resolve, 30000));
          return publicIP.ip_address;
        }
      }
    }

    if ((i + 1) % 5 === 0) {
      console.log(`  Status: ${droplet.status || 'unknown'} (${i + 1}/${maxAttempts})`);
    }

    await new Promise(resolve => setTimeout(resolve, 3000));
  }

  throw new Error('Timeout waiting for droplet to be ready');
}

async function waitForSSH(ip, sshKeyPath = null, maxAttempts = 120) {
  console.log('Waiting for SSH to be available...');
  console.log('This can take 1-3 minutes for the droplet to fully boot...');

  // Determine which keys to try
  let keyPaths = [];

  if (sshKeyPath) {
    // Use specified key
    if (!fs.existsSync(sshKeyPath)) {
      throw new Error(`SSH key not found at: ${sshKeyPath}`);
    }
    keyPaths = [sshKeyPath];
    console.log(`🔑 Using specified SSH key: ${sshKeyPath}`);
  } else {
    // Try both common SSH key locations
    keyPaths = [
      path.join(process.env.HOME, '.ssh', 'id_ed25519'),
      path.join(process.env.HOME, '.ssh', 'id_rsa')
    ].filter(p => fs.existsSync(p));

    if (keyPaths.length === 0) {
      console.warn('⚠️  No SSH private key found at ~/.ssh/id_ed25519 or ~/.ssh/id_rsa');
      console.warn('Use --ssh-key option to specify a custom key path');
      console.warn('You will need to use the root password emailed to you');
      throw new Error('No SSH private key found');
    }

    console.log(`🔑 Found ${keyPaths.length} SSH key(s) to try:`);
    keyPaths.forEach(p => console.log(`   - ${p}`));
  }

  for (let i = 0; i < maxAttempts; i++) {
    for (const keyPath of keyPaths) {
      try {
        if (i === 0) {
          console.log(`  Trying key: ${path.basename(keyPath)}`);
        }

        // Read the key - try both string and buffer
        let privateKey;
        try {
          privateKey = fs.readFileSync(keyPath, 'utf8');
        } catch {
          privateKey = fs.readFileSync(keyPath);
        }

        const sshConfig = {
          host: ip,
          username: 'root',
          privateKey: privateKey,
          readyTimeout: 10000,
          tryKeyboard: false
        };

        // Add passphrase if provided via environment variable
        if (process.env.SSH_PASSPHRASE) {
          sshConfig.passphrase = process.env.SSH_PASSPHRASE;
        }

        await ssh.connect(sshConfig);

        console.log(`✅ SSH connection established using ${path.basename(keyPath)}!`);
        return;
      } catch (error) {
        if (i === 0) {
          console.log(`  ✗ ${path.basename(keyPath)} failed: ${error.message}`);
        }
        // Continue trying
      }
    }

    if ((i + 1) % 10 === 0) {
      console.log(`  Still waiting... (${i + 1}/${maxAttempts} attempts, ${Math.floor((i + 1) * 5 / 60)} minutes elapsed)`);
    }

    if (i === maxAttempts - 1) {
      throw new Error('SSH connection timeout. The droplet may still be booting. Try connecting manually: ssh root@' + ip);
    }

    await new Promise(resolve => setTimeout(resolve, 5000));
  }
}

async function setupWiki(ip, ownerData, sshKeyPath = null) {
  console.log('\n📦 Setting up wiki on droplet...');

  try {
    // Connect via SSH
    await waitForSSH(ip, sshKeyPath);

    // Upload owner.json
    if (ownerData) {
      const ownerPath = path.join(__dirname, 'owner.json');
      await ssh.putFile(ownerPath, '/tmp/owner.json');
      console.log('✅ Uploaded owner configuration');
    }

    // Upload custom CSS
    const cssPath = path.join(__dirname, 'custom-style.css');
    if (fs.existsSync(cssPath)) {
      await ssh.putFile(cssPath, '/tmp/custom-style.css');
      console.log('✅ Uploaded custom dark purple theme');
    }

    // Upload Welcome Visitors page
    const welcomePath = path.join(__dirname, 'welcome-visitors.json');
    if (fs.existsSync(welcomePath)) {
      await ssh.putFile(welcomePath, '/tmp/welcome-visitors.json');
      console.log('✅ Uploaded Welcome Visitors page');
    }

    // Upload and execute setup script
    const setupScriptPath = path.join(__dirname, 'setup-wiki.sh');
    await ssh.putFile(setupScriptPath, '/tmp/setup-wiki.sh');
    console.log('✅ Uploaded setup script');

    // Make script executable and run it (pass domain name if provided)
    await ssh.execCommand('chmod +x /tmp/setup-wiki.sh');
    const domainArg = (ownerData && ownerData.domain) ? ownerData.domain : '';
    const result = await ssh.execCommand(`/tmp/setup-wiki.sh ${domainArg}`);

    console.log('\n--- Setup Script Output ---');
    console.log(result.stdout);
    if (result.stderr) {
      console.error('Errors:', result.stderr);
    }

    ssh.dispose();

    return result.code === 0;
  } catch (error) {
    ssh.dispose();
    throw error;
  }
}

async function deployBase(baseName, options = {}) {
  try {
    console.log('\n==================================');
    console.log(`Deploying Fedwiki Base: ${baseName}`);
    console.log('==================================\n');

    // Configure owner if not skipped
    let ownerData = null;
    if (!options.skipConfig) {
      ownerData = await configureOwner();
    }

    // Select project if specified
    let project = null;
    if (options.project) {
      console.log(`📂 Selecting project: ${options.project}...`);
      project = await selectProject(options.project);
      if (project) {
        console.log(`✅ Project selected: ${project.name}`);
      }
    }

    // Get all SSH keys from account
    console.log('🔑 Fetching SSH keys from your Digital Ocean account...');
    const sshKeyIds = await getAllSSHKeys();

    if (sshKeyIds.length === 0) {
      console.log('⚠️  No SSH keys found in your account');
      console.log('⚠️  Root password will be emailed to you');
      console.log('⚠️  For better security, add SSH keys to your DO account:');
      console.log('   https://cloud.digitalocean.com/account/security');
      console.log('');

      const readline = require('readline');
      const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout
      });

      await new Promise((resolve) => {
        rl.question('Press Enter to continue with password authentication... ', () => {
          rl.close();
          resolve();
        });
      });
    } else {
      console.log(`✅ Found ${sshKeyIds.length} SSH key(s) - will be added to droplet`);
    }

    // Create droplet
    console.log('🚀 Creating Digital Ocean droplet...');
    const dropletConfig = {
      name: baseName,
      region: options.region || 'nyc3',
      size: options.size || 's-1vcpu-1gb',
      image: 'ubuntu-22-04-x64',
      tags: ['planet-nine', 'fedwiki', 'allyabase'],
      ssh_keys: sshKeyIds
    };

    let response;
    try {
      response = await api.droplet.createDroplet(dropletConfig);
    } catch (error) {
      if (error.response?.status === 403) {
        console.error('\n❌ API Token Permission Error');
        console.error('Your Digital Ocean API token does not have permission to create droplets.');
        console.error('');
        console.error('To fix this:');
        console.error('1. Go to: https://cloud.digitalocean.com/account/api/tokens');
        console.error('2. Click "Generate New Token"');
        console.error('3. Give it a name (e.g., "base-launcher")');
        console.error('4. ⚠️  IMPORTANT: Select "Full Access" or check both "Read" and "Write"');
        console.error('5. Copy the new token');
        console.error('6. Update do-token.json with the new token');
        console.error('');
        throw new Error('API token lacks required permissions');
      }
      throw error;
    }

    const droplet = response.body?.droplet || response.data?.droplet || response.droplet;

    console.log(`✅ Droplet created!`);
    console.log(`   ID: ${droplet.id}`);

    // Wait for droplet to be ready and get IP
    const ip = await waitForDropletReady(droplet.id);

    // Assign droplet to project
    if (project) {
      console.log(`📂 Assigning droplet to project: ${project.name}...`);
      const assigned = await assignDropletToProject(droplet.id, project.id);
      if (assigned) {
        console.log(`✅ Droplet assigned to project`);
      }
    }

    // Create DNS record if domain provided
    if (ownerData && ownerData.domain) {
      await createDNSRecord(ownerData.domain, null, ip);
    }

    // Setup wiki
    const setupSuccess = await setupWiki(ip, ownerData, options.sshKey);

    if (setupSuccess) {
      console.log('\n==================================');
      console.log('🎉 Deployment Complete!');
      console.log('==================================\n');

      if (ownerData && ownerData.domain) {
        console.log(`Wiki URL: https://${ownerData.domain}`);
        console.log(`IP Address: ${ip}`);
        console.log(`\n🔒 Security:`);
        console.log(`  SSL: ✅ Enabled (Let's Encrypt)`);
        console.log(`  Auto-renewal: ✅ Configured`);
        console.log(`  Firewall: ✅ Only ports 22, 443 open`);
        console.log(`  SSH Keys: ✅ ${sshKeyIds.length} key(s) configured`);
      } else {
        console.log(`Wiki URL: http://${ip}`);
        console.log(`\n⚠️  Security:`);
        console.log(`  SSL: ❌ Not configured (HTTP only)`);
        console.log(`  Firewall: ✅ Only ports 22, 443 open`);
        console.log(`  SSH Keys: ${sshKeyIds.length > 0 ? '✅' : '⚠️ '} ${sshKeyIds.length} key(s) configured`);
      }

      console.log(`\nDroplet ID: ${droplet.id}`);

      if (ownerData) {
        console.log(`\nFederation Details:`);
        console.log(`  Location: ${ownerData.locationEmoji}`);
        console.log(`  Federation: ${ownerData.federationEmoji}`);
      }

      console.log('\nNext steps:');
      console.log('1. Visit the wiki URL');
      console.log('2. Create an "allyabase" page to activate the plugin');
      console.log('3. Launch the allyabase ecosystem from the plugin UI');

      if (ownerData && ownerData.domain) {
        console.log('\nDNS Status:');
        console.log('  Check propagation: dig +short ' + ownerData.domain);
        console.log('  Or visit: https://dnschecker.org/#A/' + ownerData.domain);
      }
      console.log('');
    } else {
      throw new Error('Wiki setup failed');
    }

    return { droplet, ip, ownerData };
  } catch (error) {
    console.error('Deployment failed:', error.message);
    throw error;
  }
}

// CLI usage
if (require.main === module) {
  const baseName = process.argv[2];

  if (!baseName) {
    console.error('Usage: node deploy-do.js <base-name> [options]');
    console.error('');
    console.error('Options:');
    console.error('  --skip-config  Skip owner configuration (use for testing)');
    console.error('  --region <r>   Digital Ocean region (default: nyc3)');
    console.error('  --size <s>     Droplet size (default: s-1vcpu-1gb)');
    console.error('  --project <p>  Project name or ID to assign droplet to');
    console.error('  --ssh-key <k>  Path to SSH private key (default: auto-detect)');
    process.exit(1);
  }

  const options = {};
  for (let i = 3; i < process.argv.length; i++) {
    const arg = process.argv[i];
    if (arg === '--skip-config') {
      options.skipConfig = true;
    } else if (arg === '--region') {
      options.region = process.argv[++i];
    } else if (arg === '--size') {
      options.size = process.argv[++i];
    } else if (arg === '--project') {
      options.project = process.argv[++i];
    } else if (arg === '--ssh-key') {
      options.sshKey = process.argv[++i];
    }
  }

  deployBase(baseName, options)
    .then(() => process.exit(0))
    .catch(() => process.exit(1));
}

module.exports = { deployBase };
