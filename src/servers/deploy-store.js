#!/usr/bin/env node

const { createApiClient } = require('dots-wrapper');
const { NodeSSH } = require('node-ssh');
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const { configureOwner } = require('./configure-owner');

// Load API token from gitignored file
const tokenPath = path.join(__dirname, 'do-token.json');
const { token } = JSON.parse(fs.readFileSync(tokenPath, 'utf8'));

const api = createApiClient({ token });
const ssh = new NodeSSH();

// Reuse functions from deploy-do.js
async function getAllSSHKeys() {
  try {
    const response = await api.sshKey.listSshKeys({ page: 1, per_page: 100 });
    const keys = response.data?.ssh_keys || response.ssh_keys || [];
    return keys.map(key => key.id);
  } catch (error) {
    if (error.response?.status === 403) {
      console.warn('⚠️  API token does not have permission to read SSH keys');
      console.warn('⚠️  Your token needs "read" scope for SSH keys');
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
    const parts = domain.split('.');
    const rootDomain = parts.length > 2 ? parts.slice(-2).join('.') : domain;
    const recordName = parts.length > 2 ? parts.slice(0, -2).join('.') : '@';

    console.log(`\n🌐 Creating DNS A record for ${domain}...`);
    console.log(`   Root domain: ${rootDomain}`);
    console.log(`   Record name: ${recordName}`);
    console.log(`   Points to: ${ip}`);

    await api.domain.createDomainRecord({
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
    console.warn('');
    console.warn('Manual DNS Setup:');
    console.warn(`  Type: A`);
    console.warn(`  Name: ${domain}`);
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

    if (droplet.status === 'active') {
      const networks = droplet.networks?.v4;
      if (networks && networks.length > 0) {
        const publicIP = networks.find(net => net.type === 'public');
        if (publicIP) {
          console.log(`✅ Droplet is active with IP: ${publicIP.ip_address}`);
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

  let keyPaths = [];

  if (sshKeyPath) {
    if (!fs.existsSync(sshKeyPath)) {
      throw new Error(`SSH key not found at: ${sshKeyPath}`);
    }
    keyPaths = [sshKeyPath];
    console.log(`🔑 Using specified SSH key: ${sshKeyPath}`);
  } else {
    keyPaths = [
      path.join(process.env.HOME, '.ssh', 'id_ed25519'),
      path.join(process.env.HOME, '.ssh', 'id_rsa')
    ].filter(p => fs.existsSync(p));

    if (keyPaths.length === 0) {
      console.warn('⚠️  No SSH private key found at ~/.ssh/id_ed25519 or ~/.ssh/id_rsa');
      console.warn('Use --ssh-key option to specify a custom key path');
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
      }
    }

    if ((i + 1) % 10 === 0) {
      console.log(`  Still waiting... (${i + 1}/${maxAttempts} attempts, ${Math.floor((i + 1) * 5 / 60)} minutes elapsed)`);
    }

    if (i === maxAttempts - 1) {
      throw new Error('SSH connection timeout. Try connecting manually: ssh root@' + ip);
    }

    await new Promise(resolve => setTimeout(resolve, 5000));
  }
}

async function scanArtifacts(artifactPath) {
  console.log(`\n📁 Scanning for artifacts in: ${artifactPath}`);

  const artifacts = {
    books: [],
    music: [],
    posts: []
  };

  function scanDirectory(dir) {
    const files = fs.readdirSync(dir);

    for (const file of files) {
      const fullPath = path.join(dir, file);
      const stat = fs.statSync(fullPath);

      if (stat.isDirectory()) {
        scanDirectory(fullPath);
      } else {
        const ext = path.extname(file).toLowerCase();

        // Books
        if (['.epub', '.pdf', '.mobi', '.azw3'].includes(ext)) {
          artifacts.books.push(fullPath);
        }
        // Music
        else if (['.mp3', '.flac', '.m4a', '.ogg', '.wav'].includes(ext)) {
          artifacts.music.push(fullPath);
        }
        // Blog posts
        else if (['.md', '.html'].includes(ext)) {
          artifacts.posts.push(fullPath);
        }
      }
    }
  }

  scanDirectory(artifactPath);

  console.log(`  ✅ Found ${artifacts.books.length} books`);
  console.log(`  ✅ Found ${artifacts.music.length} music files`);
  console.log(`  ✅ Found ${artifacts.posts.length} blog posts`);

  return artifacts;
}

async function generateFeeds(artifacts, storeName) {
  console.log('\n📚 Generating feeds...');

  const feedGeneratorPath = path.join(__dirname, '../../../tools/feed-generator');
  const feeds = {};

  // Generate books feed
  if (artifacts.books.length > 0) {
    console.log('  📖 Generating Libris feed for books...');
    const outputPath = path.join(__dirname, 'feeds', 'libris-feed.json');

    // Create temporary directory with books
    const tempBooksDir = path.join(__dirname, 'temp-books');
    fs.mkdirSync(tempBooksDir, { recursive: true });

    for (const book of artifacts.books) {
      fs.copyFileSync(book, path.join(tempBooksDir, path.basename(book)));
    }

    execSync(
      `node ${feedGeneratorPath}/generate-feed.js ${tempBooksDir} books --output ${outputPath} --name "${storeName} Books"`,
      { stdio: 'inherit' }
    );

    feeds.books = outputPath;

    // Cleanup temp directory
    fs.rmSync(tempBooksDir, { recursive: true, force: true });
  }

  // Generate posts feed
  if (artifacts.posts.length > 0) {
    console.log('  📝 Generating Scribus feed for blog posts...');
    const outputPath = path.join(__dirname, 'feeds', 'scribus-feed.json');

    const tempPostsDir = path.join(__dirname, 'temp-posts');
    fs.mkdirSync(tempPostsDir, { recursive: true });

    for (const post of artifacts.posts) {
      fs.copyFileSync(post, path.join(tempPostsDir, path.basename(post)));
    }

    execSync(
      `node ${feedGeneratorPath}/generate-feed.js ${tempPostsDir} posts --output ${outputPath} --name "${storeName} Blog"`,
      { stdio: 'inherit' }
    );

    feeds.posts = outputPath;

    fs.rmSync(tempPostsDir, { recursive: true, force: true });
  }

  // Generate music feed
  if (artifacts.music.length > 0) {
    console.log('  🎵 Generating Canimus feed for music...');
    const outputPath = path.join(__dirname, 'feeds', 'canimus-feed.json');

    const tempMusicDir = path.join(__dirname, 'temp-music');
    fs.mkdirSync(tempMusicDir, { recursive: true });

    for (const track of artifacts.music) {
      fs.copyFileSync(track, path.join(tempMusicDir, path.basename(track)));
    }

    execSync(
      `node ${feedGeneratorPath}/generate-feed.js ${tempMusicDir} music --output ${outputPath} --name "${storeName} Music"`,
      { stdio: 'inherit' }
    );

    feeds.music = outputPath;

    fs.rmSync(tempMusicDir, { recursive: true, force: true });
  }

  console.log('  ✅ Feeds generated successfully');
  return feeds;
}

async function setupStore(ip, ownerData, artifacts, feeds, storeName, sshKeyPath = null) {
  console.log('\n📦 Setting up store on droplet...');

  try {
    await waitForSSH(ip, sshKeyPath);

    // Upload owner.json
    if (ownerData) {
      const ownerPath = path.join(__dirname, 'owner.json');
      await ssh.putFile(ownerPath, '/tmp/owner.json');
      console.log('✅ Uploaded owner configuration');
    }

    // Upload artifacts
    console.log('📤 Uploading artifacts...');
    const artifactsDir = '/root/artifacts';
    await ssh.execCommand(`mkdir -p ${artifactsDir}/books ${artifactsDir}/music ${artifactsDir}/posts`);

    for (const book of artifacts.books) {
      await ssh.putFile(book, `${artifactsDir}/books/${path.basename(book)}`);
    }
    console.log(`  ✅ Uploaded ${artifacts.books.length} books`);

    for (const track of artifacts.music) {
      await ssh.putFile(track, `${artifactsDir}/music/${path.basename(track)}`);
    }
    console.log(`  ✅ Uploaded ${artifacts.music.length} music files`);

    for (const post of artifacts.posts) {
      await ssh.putFile(post, `${artifactsDir}/posts/${path.basename(post)}`);
    }
    console.log(`  ✅ Uploaded ${artifacts.posts.length} blog posts`);

    // Upload feeds
    console.log('📤 Uploading feeds...');
    await ssh.execCommand('mkdir -p /root/feeds');

    if (feeds.books) {
      await ssh.putFile(feeds.books, '/root/feeds/libris-feed.json');
      console.log('  ✅ Uploaded books feed');
    }

    if (feeds.posts) {
      await ssh.putFile(feeds.posts, '/root/feeds/scribus-feed.json');
      console.log('  ✅ Uploaded posts feed');
    }

    if (feeds.music) {
      await ssh.putFile(feeds.music, '/root/feeds/canimus-feed.json');
      console.log('  ✅ Uploaded music feed');
    }

    // Upload and execute setup script
    const setupScriptPath = path.join(__dirname, 'setup-store.sh');
    await ssh.putFile(setupScriptPath, '/tmp/setup-store.sh');
    console.log('✅ Uploaded setup script');

    await ssh.execCommand('chmod +x /tmp/setup-store.sh');
    const domainArg = (ownerData && ownerData.domain) ? ownerData.domain : '';
    const result = await ssh.execCommand(`/tmp/setup-store.sh ${domainArg} "${storeName}"`);

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

async function deployStore(storeName, artifactPath, options = {}) {
  try {
    console.log('\n==================================');
    console.log(`Deploying Planet Nine Store: ${storeName}`);
    console.log('==================================\n');

    // Scan for artifacts
    const artifacts = await scanArtifacts(artifactPath);

    const totalArtifacts = artifacts.books.length + artifacts.music.length + artifacts.posts.length;
    if (totalArtifacts === 0) {
      throw new Error('No artifacts found! Make sure the directory contains .epub, .mp3, or .md files');
    }

    // Generate feeds
    const feeds = await generateFeeds(artifacts, storeName);

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
    } else {
      console.log(`✅ Found ${sshKeyIds.length} SSH key(s) - will be added to droplet`);
    }

    // Create droplet
    console.log('🚀 Creating Digital Ocean droplet...');
    const dropletConfig = {
      name: storeName,
      region: options.region || 'nyc3',
      size: options.size || 's-1vcpu-1gb',
      image: 'ubuntu-22-04-x64',
      tags: ['planet-nine', 'store', 'sanora'],
      ssh_keys: sshKeyIds
    };

    const response = await api.droplet.createDroplet(dropletConfig);
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

    // Setup store
    const setupSuccess = await setupStore(ip, ownerData, artifacts, feeds, storeName, options.sshKey);

    if (setupSuccess) {
      console.log('\n==================================');
      console.log('🎉 Store Deployment Complete!');
      console.log('==================================\n');

      if (ownerData && ownerData.domain) {
        console.log(`Store URL: https://${ownerData.domain}`);
        console.log(`Feed URLs:`);
        if (feeds.books) console.log(`  Books: https://${ownerData.domain}/feeds/books`);
        if (feeds.posts) console.log(`  Posts: https://${ownerData.domain}/feeds/posts`);
        if (feeds.music) console.log(`  Music: https://${ownerData.domain}/feeds/music`);
      } else {
        console.log(`Store URL: http://${ip}`);
        console.log(`Feed URLs:`);
        if (feeds.books) console.log(`  Books: http://${ip}/feeds/books`);
        if (feeds.posts) console.log(`  Posts: http://${ip}/feeds/posts`);
        if (feeds.music) console.log(`  Music: http://${ip}/feeds/music`);
      }

      console.log(`\nIP Address: ${ip}`);
      console.log(`Droplet ID: ${droplet.id}`);

      console.log('\nNext steps:');
      console.log('1. Visit the store URL');
      console.log('2. Browse your digital artifacts');
      console.log('3. Subscribe to feeds in your reader');
      console.log('');
    } else {
      throw new Error('Store setup failed');
    }

    // Cleanup local feeds directory
    fs.rmSync(path.join(__dirname, 'feeds'), { recursive: true, force: true });

    return { droplet, ip, ownerData, artifacts, feeds };
  } catch (error) {
    console.error('Deployment failed:', error.message);
    throw error;
  }
}

// CLI usage
if (require.main === module) {
  const storeName = process.argv[2];
  const artifactPath = process.argv[3];

  if (!storeName || !artifactPath) {
    console.error('Usage: node deploy-store.js <store-name> <artifact-path> [options]');
    console.error('');
    console.error('Arguments:');
    console.error('  <store-name>      Name for your store');
    console.error('  <artifact-path>   Path to directory containing artifacts');
    console.error('');
    console.error('Options:');
    console.error('  --skip-config  Skip owner configuration (use for testing)');
    console.error('  --region <r>   Digital Ocean region (default: nyc3)');
    console.error('  --size <s>     Droplet size (default: s-1vcpu-1gb)');
    console.error('  --project <p>  Project name or ID to assign droplet to');
    console.error('  --ssh-key <k>  Path to SSH private key (default: auto-detect)');
    console.error('');
    console.error('Examples:');
    console.error('  node deploy-store.js my-bookstore ./books --project allyabase');
    console.error('  node deploy-store.js music-shop ./albums --region sfo3');
    process.exit(1);
  }

  const options = {};
  for (let i = 4; i < process.argv.length; i++) {
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

  deployStore(storeName, artifactPath, options)
    .then(() => process.exit(0))
    .catch(() => process.exit(1));
}

module.exports = { deployStore };
