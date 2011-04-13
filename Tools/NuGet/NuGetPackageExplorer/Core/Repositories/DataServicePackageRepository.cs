using System;
using System.Data.Services.Client;
using System.Linq;
using System.Net;
using System.Globalization;

namespace NuGet {
    public class DataServicePackageRepository : PackageRepositoryBase {
        private readonly DataServiceContext _context;
        private DataServiceQuery<DataServicePackage> _query;
        IHttpClient _client;

        public DataServicePackageRepository(IHttpClient client)
        {
            if (null == client)
            {
                throw new ArgumentNullException("client");
            }
            _client = client;
            _context = new DataServiceContext(client.Uri);

            _context.SendingRequest += OnSendingRequest;
            _context.ReadingEntity += OnReadingEntity;
            _context.IgnoreMissingProperties = true;
        }

        public override string Source {
            get {
                return _context.BaseUri.OriginalString;
            }
        }

        private void OnReadingEntity(object sender, ReadingWritingEntityEventArgs e) {
            var package = (DataServicePackage)e.Entity;

            // REVIEW: This is the only way (I know) to download the package on demand
            // GetReadStreamUri cannot be evaluated inside of OnReadingEntity. Lazily evaluate it inside DownloadPackage
            package.Context = _context;
        }

        private void OnSendingRequest(object sender, SendingRequestEventArgs e) {
            _client.InitializeRequest(e.Request);
        }

        public override IQueryable<IPackage> GetPackages() {
            if (_query == null) {
                _query = _context.CreateQuery<DataServicePackage>(Constants.PackageServiceEntitySetName);
            }
            return _query;
        }
    }
}
