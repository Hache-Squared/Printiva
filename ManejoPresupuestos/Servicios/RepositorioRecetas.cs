using Dapper;
using ManejoPresupuestos.Models;
using Microsoft.Data.SqlClient;
namespace ManejoPresupuestos.Servicios
{
    public interface IRepositorioRecetas
    {
        Task<IEnumerable<Inventario>> ObtenerTodos();
        Task<IEnumerable<InventarioParaReceta>> ObtenerInventariosReceta(ParametroObtenerInventariosParaReceta modelo);
        Task<Inventario?> ObtenerPorId(int id);
        Task Actualizar(Inventario inventario);
        Task Borrar(int id);
    }

    public class RepositorioRecetas : IRepositorioRecetas
    {
        private readonly string connectionString;

        public RepositorioRecetas(IConfiguration configuration)
        {
            connectionString = configuration.GetConnectionString("DefaultConnection");
        }

        public async Task<IEnumerable<Inventario>> ObtenerTodos()
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<Inventario>(
                @"
                    SELECT * FROM TblInventarios ORDER BY FechaCreacion DESC, InventarioId DESC
                "
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
    }
}
