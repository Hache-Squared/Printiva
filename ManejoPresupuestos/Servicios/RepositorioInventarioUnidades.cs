using Dapper;
using ManejoPresupuestos.Models;
using Microsoft.Data.SqlClient;

namespace ManejoPresupuestos.Servicios
{
    public interface IRepositorioInventarioUnidades
    {
        Task<IEnumerable<InventarioUnidad>> ObtenerTodos();
        Task<InventarioUnidad?> ObtenerPorId(int id);
    }

    public class RepositorioInventarioUnidades : IRepositorioInventarioUnidades
    {
        private readonly string connectionString;

        public RepositorioInventarioUnidades(IConfiguration configuration)
        {
            connectionString = configuration.GetConnectionString("DefaultConnection");
        }

        public async Task<IEnumerable<InventarioUnidad>> ObtenerTodos()
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<InventarioUnidad>(
                @"
                    SELECT * FROM TblInventariosUnidades
                "
            );
        }

        public async Task<InventarioUnidad?> ObtenerPorId(int id)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryFirstOrDefaultAsync<InventarioUnidad>(
                @"
                    SELECT * FROM TblInventariosUnidades WHERE InventarioUnidadId = @Id
                ",
                new { id }
            );
        }
    }
}
