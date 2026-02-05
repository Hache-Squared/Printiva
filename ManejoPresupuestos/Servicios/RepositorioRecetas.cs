using Dapper;
using ManejoPresupuestos.Models;
using Microsoft.Data.SqlClient;
using static ClosedXML.Excel.XLPredefinedFormat;
namespace ManejoPresupuestos.Servicios
{
    public interface IRepositorioRecetas
    {
        Task<IEnumerable<RecetaMostarIndex>> ObtenerTodos(ParametroObtenerRecetas param);
        Task<IEnumerable<InventarioParaReceta>> ObtenerInventariosReceta(ParametroObtenerInventariosParaReceta modelo);
        Task<ResultProcedureGeneric> CrearReceta(ParametroAlterarReceta param);
        Task<ResultProcedureGeneric> CrearRelacionRecetaInventario(ParametroCrearRelacionRecetaInventario param);

        Task<RecetaProductoViewModel> ObtenerRecetaPorId(int id, int loginId);
        Task<IEnumerable<InventarioParaReceta>> ObtenerRecetaInventarioNecesario(int id, int loginId);
        Task<Inventario?> ObtenerPorId(int id);
        Task Actualizar(Inventario inventario);
        Task Borrar(int id);
        Task<ResultProcedureGeneric> ReplicarReceta(int recetaIdOrigen, int loginId, string? nombreNuevo = null, int? productoIdNuevo = null);
        Task<ResultProcedureGeneric> DesactivarReceta(int recetaId, int loginId);
    }

    public class RepositorioRecetas : IRepositorioRecetas
    {
        private readonly string connectionString;

        public RepositorioRecetas(IConfiguration configuration)
        {
            connectionString = configuration.GetConnectionString("DefaultConnection");
        }

        public async Task<IEnumerable<RecetaMostarIndex>> ObtenerTodos(ParametroObtenerRecetas param)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<RecetaMostarIndex>(
                "dbo.procObtenerRecetas",
                new
                {
                    loginId = param.LoginId,
                    ElementoObtenerId = param.ElementoObtenerId

                },
                commandType: System.Data.CommandType.StoredProcedure
            );

        }

        public async Task<IEnumerable<InventarioParaReceta>> ObtenerInventariosReceta(ParametroObtenerInventariosParaReceta modelo)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<InventarioParaReceta>(
                "dbo.procObtenerInventarios",
                new
                {
                    loginId = modelo.LoginId,
                    ElementoObtenerId = modelo.ElementoObtenerId

                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }
        public async Task<ResultProcedureGeneric> CrearReceta(ParametroAlterarReceta param)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QuerySingleAsync<ResultProcedureGeneric>(
                "dbo.procAlteraReceta",
                new
                {
                    Nombre = param.Nombre,

                    // legacy
                    TiempoImpresion = param.Tiempo,

                    // nuevos
                    TiempoImpresionMin = param.TiempoImpresionMin,
                    TiempoPostMin = param.TiempoPostMin,

                    ProductoId = param.ProductoId,
                    loginId = param.LoginId,
                    Actualizar = param.Actualizar,
                    Borrar = param.Borrar,
                    ElementoAlterarId = param.ElementoAlterarId,
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }
        
        public async Task<ResultProcedureGeneric> CrearRelacionRecetaInventario(ParametroCrearRelacionRecetaInventario param)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QuerySingleAsync<ResultProcedureGeneric>(
                "dbo.procAlteraRecetaRelacion",
                new
                {
                    Json = param.Json,
                    ElementoAlterarId = param.RecetaId,
                    loginId = param.LoginId
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<Inventario?> ObtenerPorId(int id)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryFirstOrDefaultAsync<Inventario>(
                @"
                    SELECT * FROM TblInventarios WHERE InventarioId = @Id
                ",
                new { id }
            );
        }

        public async Task Actualizar(Inventario inventario)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.QueryFirstOrDefaultAsync<Inventario>(
                @"
                    UPDATE TblInventarios SET InventarioMarcaId = @InventarioMarcaId, InventarioTipoId = @InventarioTipoId, InventarioNombreId = @InventarioNombreId, InventarioColorId = @InventarioColorId, Cantidad = @Cantidad, InventarioUnidadId = @InventarioUnidadId, FechaCreacion = @FechaCreacion
                    WHERE InventarioId = @InventarioId;
                ",
                inventario
            );
        }

        public async Task Borrar(int id)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.QueryFirstOrDefaultAsync<Inventario>(
                @"
                    DELETE TblInventarios WHERE InventarioId = @id;
                ",
                new { id }
            );
        }

        public async Task<RecetaProductoViewModel> ObtenerRecetaPorId(int id, int loginId)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QuerySingleAsync<RecetaProductoViewModel>(
                "dbo.procObtenerRecetas",
                new
                {
                    ElementoObtenerId = id,
                    loginId = loginId
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<IEnumerable<InventarioParaReceta>> ObtenerRecetaInventarioNecesario(int id, int loginId)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<InventarioParaReceta>(
                "dbo.procObtenerRecetaInventario",
                new
                {
                    loginId = loginId,
                    ElementoObtenerId = id

                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task<ResultProcedureGeneric> ReplicarReceta(int recetaIdOrigen, int loginId, string? nombreNuevo = null, int? productoIdNuevo = null)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QuerySingleAsync<ResultProcedureGeneric>(
                "dbo.procReplicarReceta",
                new
                {
                    loginId,
                    RecetaIdOrigen = recetaIdOrigen,
                    NombreNuevo = nombreNuevo,
                    ProductoIdNuevo = productoIdNuevo
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }
        public async Task<ResultProcedureGeneric> DesactivarReceta(int recetaId, int loginId)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QuerySingleAsync<ResultProcedureGeneric>(
                "dbo.procDesactivarReceta",
                new
                {
                    loginId,
                    RecetaId = recetaId
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }
    }
}
